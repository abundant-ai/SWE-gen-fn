The OCaml runtime currently exposes `caml_c_thread_register()` for external (non-OCaml-created) C threads to attach to the runtime so they can call into OCaml. However, `caml_c_thread_register()` always registers the calling C thread into domain 0, which prevents external C threads from attaching to and running OCaml code in parallel on other running domains.

Implement a new runtime API:

```c
int caml_c_thread_register_in_domain(uintnat domain_unique_id);
```

This function must attempt to register the calling C thread with the OCaml runtime in the domain identified by `domain_unique_id` (the domain’s unique ID). It must return non-zero/true on success and zero/false on failure.

Behavior requirements:

- When a C thread calls `caml_c_thread_register_in_domain(id)` with an ID corresponding to a domain that is currently running, registration must succeed. After successful registration, the C thread must be able to call into OCaml (e.g., acquire the runtime, invoke an OCaml callback, release the runtime) and observe that `Domain.self()` reflects the domain it registered into.

- `caml_c_thread_register()` must keep its current behavior: it always registers the C thread into domain 0, even if called while other domains exist.

- Registration must fail (return 0/false) if the supplied `domain_unique_id` does not correspond to a currently running domain at the time of the call. This includes:
  - a domain unique ID that belonged to a domain that has already terminated
  - a domain unique ID that has never existed

  In this failure case, the C thread must not be considered registered, and it must be safe for the C code to skip calling `caml_acquire_runtime_system()` / OCaml callbacks.

- It must be possible for the same external C thread to unregister and later register again into a different domain by calling `caml_c_thread_unregister()` followed by `caml_c_thread_register_in_domain(other_id)`. The second registration should succeed or fail based on whether `other_id` refers to a currently running domain.

Example expected observable behavior from an embedding that spawns domains and uses an external C thread to call back into OCaml:

- Registering with `caml_c_thread_register()` and then calling an OCaml function that prints `Domain.self()` should print domain 0.
- Registering with `caml_c_thread_register_in_domain(3)` while domain 3 is running should allow the callback to print domain 3.
- Attempting `caml_c_thread_register_in_domain(3)` after domain 3 has terminated should fail and print an error like:

```
Failed to register thread in domain 3
```

- Attempting to register in a non-existent domain ID (e.g., 6 when no such running domain exists) should fail similarly.
- Registering first into one domain and then (after unregistering) into another domain should reflect the correct domain each time, and if the first attempt fails, a later attempt may succeed if that domain becomes running.

The key missing capability is correct domain-targeted registration for external C threads, with strict failure when the requested domain unique ID is not currently running.
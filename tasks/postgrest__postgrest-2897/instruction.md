PostgREST has a regression in v11 where, after switching into an impersonated database role for a request, it incorrectly applies session settings (GUCs) that belong to the authenticator role (or otherwise uses “superuser-only” role settings in the wrong context). This can break requests and even prevent PostgREST from starting in environments where role-level configuration contains privileged parameters.

Two user-visible failures need to be addressed:

1) Requests can fail when the authenticator role has a role-level setting that the impersonated role is not allowed to set. Example: if the authenticator role has `log_min_duration_statement = -1` (or any privileged `ALTER ROLE ... SET` GUC), and a request is made that impersonates a less-privileged role (e.g. via JWT `role`), the request fails with:

```json
{
  "code": "42501",
  "details": null,
  "hint": null,
  "message": "permission denied to set parameter \"log_min_duration_statement\""
}
```

Expected behavior: switching to an impersonated role should not attempt to apply role settings that are not applicable/allowed for that role. The request should succeed if the impersonated role has the required database privileges for the SQL being run.

2) In some setups (notably local runs of the project’s IO/CLI test harness), PostgREST fails early while querying database settings/config parameters and repeatedly retries with a connection error like:

```
An error ocurred when trying to query database settings for the config parameters
{"code":"PGRST000","details":"connection to server on socket \"/run/postgresql/.s.PGSQL.5432\" failed: fe_sendauth: no password supplied\n","hint":null,"message":"Database connection error. Retrying the connection."}
connection to server on socket "/run/postgresql/.s.PGSQL.5432" failed: fe_sendauth: no password supplied
```

Expected behavior: PostgREST should be able to start and run CLI/config introspection without tripping over role-impersonation/session-setting logic that causes it to use the wrong connection context or to apply invalid/privileged session settings.

Implement/fix the impersonation and session-setup logic so that when PostgREST transitions from the authenticator role to an impersonated role for a request, it does not carry over or attempt to apply authenticator role GUCs that require elevated privileges or that the impersonated role cannot set. The role used for applying settings must match the effective role context, and any role-level superuser-only settings must not be applied in a way that breaks impersonated requests.
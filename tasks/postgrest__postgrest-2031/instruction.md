When a request contains an ambiguous resource embedding, PostgREST returns a 300 Multiple Choices error with a JSON body containing "message", "details", and "hint". Today the "hint" uses generic examples like "/origin?select=relationship(*)" or "/origin?select=target!relationship(*)", which is confusing during upgrades and does not help users pick the correct disambiguation syntax for the specific query.

Update the ambiguous embedding error response so that the "hint" includes valid, query-relevant disambiguation examples using the real `target!relationship` names for the ambiguous embed. The hint must be constructed from the set of ambiguous relationships reported in "details" and should instruct the user to change the embedded resource name to one of the concrete options.

For example, if a request embeds `sender` and there are multiple relationships, the response should include a hint like:

"Try changing 'sender' to one of the following: 'person!message_sender_fkey', 'person_detail!message_sender_fkey'. Find the desired relationship in the 'details' key."

Similarly, if a request embeds `big_projects` and multiple relationships exist with different relationship names, the hint should list options like:

"Try changing 'big_projects' to one of the following: 'big_projects!main_project', 'big_projects!jobs', 'big_projects!main_jobs'. Find the desired relationship in the 'details' key."

The overall error should still be a 300 response and must keep the existing structure:
- "message" should clearly say it could not embed because more than one relationship was found for the origin resource and the embedded name
- "details" should remain an array of objects describing each candidate relationship (including fields like "cardinality", "relationship", and "embedding")
- "hint" should no longer contain generic URL examples; it must list concrete replacement strings matching PostgREST embed-disambiguation syntax (`target!relationship`) relevant to the ambiguous embedding name in the request.

The behavior must work for ambiguous cases such as:
- a table and a view both matching the same foreign-key-based embed name
- ambiguity between one-to-many and many-to-many paths to the same target resource
- ambiguous embeds involving circular references

In all cases, the returned hint must only suggest options that are valid for that specific ambiguity and must match the relationship identifiers presented in "details" so users can choose correctly.
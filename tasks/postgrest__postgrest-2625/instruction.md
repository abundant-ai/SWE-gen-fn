When PostgREST fails to connect to PostgreSQL due to an authentication error (e.g., wrong password), it should treat this as a fatal startup error and exit immediately with a non-zero exit code, rather than logging “Database connection error. Retrying the connection.” and continuing to retry.

Currently, authentication failure detection is too strict and fails to recognize real-world libpq error strings. For example, with an invalid password, PostgreSQL/libpq can produce details like:

connection to server at "postgres" (172.18.0.2), port 5432 failed: FATAL:  password authentication failed for user "xxx"

PostgREST’s logic only recognizes authentication failure when the details message starts with the authentication failure text, so the above format is misclassified as a retriable connection error.

Update the connection error handling so that PostgreSQL password authentication failures are recognized even when the relevant substring (e.g., "FATAL:  password authentication failed") appears later in the error details rather than at the beginning. In this case, PostgREST must stop retrying and terminate.

Reproduction scenario: start PostgREST with a database URI that specifies a valid host/db/user but an invalid password, e.g.:

postgresql://?dbname=<db>&host=<host>&user=some_protected_user&password=invalid_pass

Expected behavior: PostgREST exits promptly and the process exit code is 1.

Actual behavior: PostgREST keeps running and periodically logs that it is retrying the database connection.
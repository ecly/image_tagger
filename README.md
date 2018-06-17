# ImageTagger

Small application for distributing the work of tagging images into two categories among multiple concurrent users. Uses GenServers for synchronizing an `ImageServer` with a folder in an S3-bucket. Based on the reviewers review, it it then moved to another appropriate folder in the S3-bucket based on the review.

Currently reviewed images are kept in a `ReviewServer` that the `ImageServer` synchronizes with to ensure that users are not served the same image.

Presigned URLs are used for serving the images to the frontend.

See [config/prod.secret.example.exs](config/prod.secret.example.exs) for configuration details.

---

The entire front-end is just hacked wildly together as a meme, but should be easily replaceable.
Same goes for the entire web portion of the Phoenix application.

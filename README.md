# ImageTagger

Small application for distributing the work of tagging images into categories among multiple concurrent users. Uses GenServers for synchronizing an `ImageServer` with a folder in an S3-bucket. 

A [Behaviour](lib/image_tagger/images/images_behaviour.ex) with callbacks `move_image_to_folder/2`, `fetch_images/0` and `get_url/1` can be implemented to allow interfacing with a local folder structure or a different remote. 

Based on a reviewer's tag, an image is moved to its  appropriate folder in S3-bucket based on the tag. 
For configuration of tags, see: [config/prod.secret.example.exs](config/prod.secret.example.exs). For the provided S3-client, presigned URLs are used for `get_url/1`.

The `ReviewServer` and `ImageServer` synchronize to ensure that users are not served the same image,
and that images are not "lost" eg. in case a Reviewer disconnects or discards an image. Additionally, the `ReviewServer` keeps track of a configurable amount of "history", allowing Reviewers to undo their tags, in case they got something wrong.


---

The entire front-end is just hacked wildly together as a meme, but should be easily replaceable.
Same goes for the entire web portion of the Phoenix application.

use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :image_tagger, ImageTaggerWeb.Endpoint, secret_key_base: ""

config :ex_aws,
  s3: [region: "eu-west-2", scheme: "https://"],
  access_key_id: ["", :instance_role],
  secret_access_key: ["", :instance_role]

# The amount of reviews we allow the user to undo at most.
config :image_tagger, password: "password"
config :image_tagger, history_size: 5
config :image_tagger, update_interval_seconds: 1
config :image_tagger, bucket_name: "bucket"
config :image_tagger, image_folder: "to_review"

# Various tags. The tag should atom should correspond
# to the atom represention of the 'tag' that the front-end
# pushes through the channel when the reviewer submits a review.
# Can be arbitrarily many tags.
config :image_tagger, bad: "bad_folder"
config :image_tagger, maybe: "maybe_folder"
config :image_tagger, good: "good_folder"

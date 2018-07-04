use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :image_tagger, ImageTaggerWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# The amount of reviews we allow the user to undo at most.
config :image_tagger, password: "password"
config :image_tagger, history_size: 5
config :image_tagger, update_interval_seconds: 100
config :image_tagger, bucket_name: "test_bucket"
config :image_tagger, image_folder: "test_image_folder"

# Various tags. The tag should atom should correspond
# to the atom represention of the 'tag' that the front-end
# pushes through the channel when the reviewer submits a review.
# Can be arbitrarily many tags.
config :image_tagger, bad: "test_bad_folder"
config :image_tagger, maybe: "test_maybe_folder"
config :image_tagger, good: "test_good_folder"

import Config

config :elixir_no_deps,
  ssh_key: """-----BEGIN OPENSSH PRIVATE KEY-----
KEYKEYKEYKEYKEYKEY
KEYKEYKEYKEYKEYKEY
KEYKEYKEYKEYKEYKEY
-----END OPENSSH PRIVATE KEY-----
""",
	local_port: 3303,
	remote_port: 9000,
	username: "username",
	hostname: "hostname"
terraform {
  cloud {
    organization = "freecodecamp"

    workspaces {
      name = "tfws-ops-github-runners"
    }
  }
}

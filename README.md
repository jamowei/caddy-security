# Caddy Security

Docker image containing [caddy](https://github.com/caddyserver/caddy) and [caddy-security](https://github.com/greenpau/caddy-security).

# Use Github OIDC

[Tutorial](https://docs.authcrunch.com/docs/authenticate/oauth/backend-oauth2-0007-github) 
and resulting `Caddyfile` (replace `mydomain.com` with your domain):
```
{
  order authenticate before respond
  order authorize before basicauth

  security {
    oauth identity provider github {env.GITHUB_CLIENT_ID} {env.GITHUB_CLIENT_SECRET}

    authentication portal auth {
      crypto default token lifetime 3600
      cookie domain mydomain.com
      enable identity provider github
      ui {
        links {
          "My Identity" "/whoami" icon "las la-user"
        }
      }

      transform user {
        match realm github
        action add role authp/user
      }

      transform user {
        match realm github
        match sub github.com/<username>
        action add role authp/admin
      }
    }

    authorization policy user {
      set auth url https://auth.mydomain.com/oauth2/github
      allow roles authp/user
      validate bearer header
      inject headers with claims
    }

    authorization policy admin {
      set auth url https://auth.mydomain.com/oauth2/github
      allow roles authp/admin
      validate bearer header
      inject headers with claims
    }
  }
}

auth.mydomain.com {
  authenticate with auth
}

mydomain.com {
  authorize with user
	reverse_proxy user:8080
}

admin.mydomain.com {
  authorize with admin
  reverse_proxy admin:8080
}
```
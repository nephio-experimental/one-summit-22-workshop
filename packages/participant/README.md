# participant

## Description
Kpt package to apply with participant specific repositories and other setup

## Usage

When you fetch the package, you should give it the name of the participant. So,
if the participant is 'workshopper', then:

```bash
PARTICIPANT=workshopper # Replace 'workshopper' with the participant name provided to you

kpt pkg get --for-deployment https://github.com/nephio-project/one-summit-22-workshop.git/packages/participant $PARTICIPANT
kpt fn render $PARTICIPANT
kpt live init $PARTICIPANT
kpt live apply $PARTICIPANT --output table
```

This assumes the GitHub basic auth secret `github-personal-access-token` has
been created with username `nephio-test` and the PAT as the password.

This will pull the package and set up the repository pointers correctly.


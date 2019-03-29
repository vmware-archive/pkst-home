# pkst-home

Home for the PKS Telementry team.  pks-telemetry@pivotal.io  or find us on slack at #pks-telemetry-eng

## Set up workstation

To set up workstation tools and configurations, run `setup`
```
> ./setup
```
### Decisions made

1. [neovim](https://github.com/neovim/neovim) is the only vim we know
1. [lolcat](https://github.com/busyloop/lolcat) is the only cat we know

## Set up environment
To set up environment variables for running `opsman` and `concourse` for Telemetry specific clusters, run `.setup_environment`

```
> ./setup_environment.rb -h
Usage: setup_environment.rb [OPTIONS]
    -u, --username USERNAME          Lastpass username containing a shared telemetry folder
    -e, --environment environment    The environment you want to setup
    -i, --url local-file-url         the url of the environment lock file
    -h, --help                       help
```

This will create a folder named `<environment-name>` in the `workspace` directory of your home. Inside that directory, you have the necessary environment already setup to run commands such as `bosh vms`.





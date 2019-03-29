# pkst-home

Home for the PKS Telementry team.

## Usage

To set up workstation environment, run `setup`
```
> ./setup
```

To set up `opman environment`, run `.setup_environment`
```
> ./setup_environment.rb -h
Usage: setup_environment.rb [OPTIONS]
    -u, --username USERNAME          Lastpass username containing a shared telemetry folder
    -e, --environment environment    The environment you want to setup
    -i, --url local-file-url         the url of the environment lock file
    -h, --help                       help
```


## Decisions made

1. [neovim](https://github.com/neovim/neovim) is the only vim we know
1. [lolcat](https://github.com/busyloop/lolcat) is the only cat we know

HomeSweetHome
=========
HomeSweetHome is based on [HomesHick](https://github.com/andsens/homeshick) from Anders Ingemann which is again based on [Homesick](https://github.com/technicalpickles/homesick)

This version has additional features:

* Redact and Unredact to mimic [Briefcase's](http://jim.github.io/briefcase/) redact and generate commands. (Taken from https://github.com/Billiam/homeshick)
* Install and Update commands to allow executing of install and update scripts.

Also this version is mainly geared toward OSX usage, to the castles you will find for it from me will be OSX based.

HomeSweetHome keeps your dotfiles up to date using only git and bash.
It can handle many dotfile repositories at once, so you can beef up your own dotfiles
with bigger projects like [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh) and still
keep everything organized.

For detailed [installation instructions](https://github.com/dredhorse/HomeSweetHome/wiki/Installation), [tutorials](https://github.com/dredhorse/HomeSweetHome/wiki/Tutorials) and [tips](https://github.com/dredhorse/HomeSweetHome/wiki/Automatic-deployment) & [tricks](https://github.com/dredhorse/HomeSweetHome/wiki/Symlinking) have a look at the [wiki](https://github.com/dredhorse/HomeSweetHome/wiki).

Note: the command homeshick and the directory homesick is still being used to maintain backwards compability!

Quick install
-------------

HomeSweetHome is installed to your own home directory and does not require root privileges to be installed.

```sh
git clone https://github.com/dredhorse/HomeSweetHome.git $HOME/.homesick/repos/homeshick
```

To invoke homeshick from sh and its derivates (bash, zsh, fish etc.) source the `homeshick.sh` script from your rc-script:
```sh
printf '\nsource "$HOME/.homesick/repos/homeshick/homeshick.sh"' >> $HOME/.bashrc
```
csh and derivatives (i.e. tcsh):
```sh
printf '\nalias homeshick source "$HOME/.homesick/repos/homeshick/bin/homeshick.csh"' >> $HOME/.cshrc
```
# Usage #

HomeSweetHome is used via subcommands, so simply typing `homeshick` will yield a helpful message
that tersely explains all of the things you can do with it.

Most subcommands accept castlenames as arguments.
You can also run a subcommand on all castles by not specifying any arguments.

## Commands ##

### link ###
This command symlinks all files that reside in the `home` folders of your castles into your home folder.
You will be prompted if there are any files or folders that would be overwritten.

If the castle does not contain a home folder it will simply be ignored.

### clone ###
The `clone` command clones a new git repository to `.homesick/repos`.
The clone command accepts a github shorthand url, so if you want to clone
oh-my-zsh you can type `homeshick clone robbyrussell/oh-my-zsh`

### pull ###
The `pull` command runs a `git pull` on your castle and any of its submodules.
If there are any new dotfiles to be linked, homeshick will prompt you whether you want to link them.

### check ###
`check` determines the state of a castle.
* There may be updates on the remote, meaning it is *behind*.
* Your castle can also contain unpushed commits, meaning it is *ahead*.
* When everything is in sync, `check` will report that your castle is *up to date*.

### list ###
You can see your installed castles by running the `list` command.

### track ###
If you have a new dotfile that you want to put in one of your castles, you can ask
homeshick to do the moving and symlinking for you.
To track your `.bashrc` and `.zshrc` in your `dotfiles` castle
run `homeshick track dotfiles .bashrc .zshrc`,
the files are automatically added to the git index.

### redact ###
If you wish to track a file containing sensitive information, you can use redact
to handle assist with sanitizing the file before storing it in your repo.
run

`homeshick redact dotfiles .file-containing-passwords`

The file will be copied to the dotfiles repo, and will be opened for editing.
When prompted, replace sensitive information with `# briefcase(name-of-password)` ex:

```diff
- my_network_password="12345"
+ my_network_password="# briefcase(network-password)"
```

The file will be saved in your repository with the .redacted filename extension.

### unredact ###
The `unredact` command generates dotfiles from your castles .redacted files into your home folder.
If present, your `~/.briefcase_secrets` file will be used to populate secrets when generating the unredacted file.

### generate ###
`generate` creates a new castle.
All you need to do now is call `track` to fill it with your dotfiles.

### refresh ###
Run this command to check if any of your repositories have not been updated the last week.
This goes very well with your rc scripts (check out the [tutorial](#tutorial) for more about this).

### install ###
Run this command to execute any included installation script  of the castle.

### update ###
Run this command to execute any included update script of the castle.

### export ###
Run this command to export a list of installed castles.

### changes ###
Run this command to check if any of your local repositories contain changes against the online repos.


## Tutorial ##

### Original machine ###

In the installation you added an alias to the `.bashrc` file with
```
printf '\nalias homeshick="$HOME/.homesick/repos/homeshick/home/.homeshick"' >> $HOME/.bashrc
```

Let's create your first castle to hold this file. You use the [generate](#generate) command to do that:
`homeshick generate dotfiles`. This creates an empty castle, which you can now populate.
Put the `.bashrc` file into your `dotfiles` castle with `homeshick track dotfiles .bashrc`.

Assuming you have a repository at the other end, let's now enter the castle, commit the changes,
add your github remote and push to it.
```
cd $HOME/.homesick/repos/dotfiles
git commit -m "Initial commit, add .bashrc"
git remote add origin git@github.com/username/dotfiles
git push -u origin master
cd -
```
*Note: The `.homesick/` folder is not a typo, it is named as such because of compatibility with
[homesick](#homeshick-and-homesick), the ruby tool that inspired homeshick*

### Other machines ###
To get your custom `.bashrc` file onto other machines you [install homeshick](#installation) and
clone your castle with: `$HOME/.homesick/repos/homeshick/home/homeshick clone username/dotfiles`
homeshick will ask you immediately whether you want to symlink the newly cloned castle.
If you agree to that and also agree to it overwriting the existing `.bashrc` you can run
`source $HOME/.bashrc` to get your `homeshick` alias running.

### Refreshing ###
You can run `check` to see whether your castles are up to date or need pushing/pulling.
This is a task that is easy to forget, which is why homeshick has the `refresh` subcommand.
It examines your castles to see when they were pulled the last time and prompts you to pull
any castles that have not been pulled over the last week.
You can put this into your `.bashrc` file to run the check everytime you start up the shell:
`printf '\nhomeshick --quiet refresh' >> $HOME/.bashrc`.
*(The `--quiet` flag makes sure your terminal is not spammed with status info on every startup)*

If you prefer to update your dotfiles every other day, simply run `homeshick refresh 2` instead.

### Updating your castle ###
To make changes to one of your castles you simply use git. For example,
if you want to update your `dotfiles` castle from a machine which
has it:

```
cd $HOME/.homesick/repos/dotfiles
git add <newdotfile>
git commit -m "Added <newdotfile>"
git push origin master
homeshick link
```

## Automatic deployment ##
After having launched ec2 instances a lot, I got tired of installing zsh, tmux etc.
Check out [this gist](https://gist.github.com/2913223).

In one line you can run a script which installs your favorite shell and multiplexer.
It also installs homeshick, which then clones and symlinks your castle(s).
To clone via ssh instead of https, you will need a private key.

You may however not trust the current server with agent forwarding,
which is why the script contains variables to hold the unencrypted deploy key of your castles
(available in the admin section of your repo).
They will be added to the ssh-agent in order for git to be able to clone. Enjoy!


# HomeSweetHome and homeshick #

HomeSweetHome was created to allow an install and update functionality to be included into homeshick. Later on some
other functions where added like the briefcase support, export and changes.

# homeshick and homesick #
The original goal of homeshick was to mimick the functionality of
[homesick](https://github.com/technicalpickles/homesick) so that it could be a drop-in replacement.
Since its inception however homeshick has deviated quite a bit from the ruby-version.
All of the original commands are still available, but have been simplified and enhanced with interactive
prompts like symlinking new files after a castle has been updated.

# HomeSweetHome and briefcase #
The redact and unredact are designed to mimic [Briefcase's](http://jim.github.io/briefcase/) redact and generate commands.


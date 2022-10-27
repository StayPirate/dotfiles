## Use python virtual-environments

In order to use a python virtual environment, you first need to install the target python version. For instance

```bash
$ pyenv install 2.7.18
Downloading Python-2.7.18.tar.xz...
-> https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz
Installing Python-2.7.18...
Installed Python-2.7.18 to /home/<user>/.config/pyenv/versions/2.7.18
```

it will be installed in `~/.config/pyenv/versions`. You can verify the installation by checking its availability with `pyenv versions`.

```bash
$ pyenv versions
* system (set by /home/<user>/.config/pyenv/version)
  2.7.18
```

You can now create a virtual environment leveraging the newly downloaded python version.

```bash
$ #Verify python before creating the virtualenv (global interpreter)
$ python --version
Python 3.8.6

$ #Create the python virtual environment
$ pyenv virtualenv 2.7.18 python_virtualenv_2.7.18
$ pyenv virtualenvs
    2.7.18/envs/python_virtualenv_2.7.18 (created from /home/<user>/.config/pyenv/versions/2.7.18)
    python_virtualenv_2.7.18 (created from /home/<user>/.config/pyenv/versions/2.7.18)

$ #Create a folder and initialized it to work with the newly created virtualenv
$ mkdir virtualenv_2.7 && cd virtualenv_2.7
$ pyenv local python_virtualenv_2.7.18
$ python --version
Python 2.7.18

$ #Delete the virtual environment
$ pyenv uninstall python_virtualenv_2.7.18
pyenv-virtualenv: remove /home/<user>/.config/pyenv/versions/2.7.18/envs/python_virtualenv_2.7.18? y
```

Using these dotfiles there is no need to activate the virtualenv once inside since [`eval "$(pyenv virtualenv-init -)"`](../zsh/.zshrc#L171) takes care of it.
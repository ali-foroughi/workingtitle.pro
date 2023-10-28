---
title: "Setting Up Python App on Virtualenv"
date: 2020-06-20
draft: fales
---

<a href="https://virtualenv.pypa.io/en/latest/">Virtualenv</a> is a tool for creating isolated environments for running your python application. Most python programs require a variety of different libraries that are needed for running the applications on any machine. So If you don’t use a virtual environment, you will have to install all the libraries all the time. Overtime this will cause conflicts between different packages. So it’s always a good idea to isolate the environment for your python project. That’s why, most of the applications need to be written in a virtual environment to avoid problems. In this guide we’re going to look at how to set up Python app on virtualenv.

Here’s what you need to do to create a virtual environment.

First, make sure that you have Python installed. You can install the latest version of Python from <a href="https://www.python.org/">python.org</a>. I recommend to use Python 3 which is the latest version with long-term support.

## Creating a virtual environment

Now we need to create a virtual environment path using this command:

```
python3 -m venv /path/to/new/virtual/environment
```
Then we can use the source command to activate the virtual environment as so:
```
source bin/activate
```

Now your shell should look something like this:

<img src="https://i.ibb.co/61T5MhZ/python01.png">

<code>new-test</code> is the directory path we created in the previous step with the <code>python3 -m</code> command. This shows that we’re currently inside the virtual environment for Python. Any package and library that you will install will only be accessible inside this virtual environment and will not have system-wide effects.

For example we’re going to install the pygame which is a set of modules for creating games in python. You can install it with the pip tool:
```
pip install pygame
```

You can connect to this virtual environment at anytime using the source command. Install all the packages and modules within this environment and run your application. I always recommend to run your python app within virtualenv to avoid environment problems in future. 

Official documentation on Python venv can be found <a href="https://docs.python.org/3/library/venv.html">here</a>. 


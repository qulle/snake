# Snake in Ada
### A snake game in the terminal using Ada

## Screenshot
![Screenshot of the program](images/snake.png?raw=true "Screenshot of the program")

## Author notes
I wrote this game during my first year at the University back in 2017. The code can be improved but i think it's good to leave it the way it was made. With some pointer operations some code could be simplified, for example when adding a new piece to the snake.

## Compiling
I compiled using GNATMAKE 7.5.0
```
$ gnatmake ./snake.adb
```

## Runtime
Normal mode
```
$ ./snake 
```

Super secret cheat mode (reversing and go through the snake now possible)
```
$ ./snake cheat
```

## Tested
The code have been tested on:
- Linux machine running Ubuntu 18.04.5 LTS with GNAT 7.5.0 
- Windows 10 machine running WSL (Windows Subsystem for Linux) and Ubuntu 18.04 LTS with GNAT 7.5.0

## Author
[Qulle](https://github.com/qulle/)
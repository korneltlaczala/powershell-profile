### Functionalities
- function to reload profile
    - save current path to a file in tmp dir
    - exit from the old session
    - launch new powershell session
    - new session will obvsly run the $profile script
    - **make an attempt to read the path from file in tmp dir** -> that will be a new function in itself
    - cd to this directory
    - maybe remove the file from tmp dir

- read init path from tmp dir
    - try to read in path from file in tmp dir
    - if no path -> return
    - cd path

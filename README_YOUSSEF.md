In order to use this implemtation MATLAB 2021B and Python 3.9.6 are needed

To train a new model:
-choose the context vector to be sent form the MATLAB environment, either corner info, relative position and velocity info, or the combined info (in the sim.run file)
-change the size of the context vector in the main and forrester_ei.yaml files in the python implementaion to 2,9 or 11 accordingly
-fetch the IP address used from the MATLAB console and type it in the main file
-a previously trained model can be loaded using the list of names provided in the main file in python
-finally run the run.m file in MATLAB then the main.py

Similarly use trained.py to test Trained models. 

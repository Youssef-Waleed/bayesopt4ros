from __future__ import annotations
from contextual_bayesopt import ContextualBayesianOptimization as cbo
import torch
import numpy as np
import socket


TCP_IP = "192.168.178.138" #IP address to be fetched from MATLAB console
TCP_PORT = 5000

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((TCP_IP, TCP_PORT))

opt = cbo.from_file("forrester_ei.yaml")



#------------------------------------
#Corner
#1st_25
#1st_50
#1st_100
#1st_150
#------------------------------------
#Relative Pos
#2nd_25
#2nd_50
#2nd_100
#2nd_150
#2nd_200
#------------------------------------
#Combined
#3rd_25
#3rd_50
#3rd_100
#3rd_150
#------------------------------------
#Corner random
#1st_25_R
#1st_50_R
#1st_100_R
#1st_150_R
#------------------------------------
#Relative Pos random
#2nd_25_R
#2nd_50_R
#2nd_100_R
#2nd_150_R
#------------------------------------
#Combined random
#3rd_25_R
#3rd_50_R
#3rd_100_R
#3rd_150_R
#------------------------------------



opt._load_prev_bayesopt("3rd_150_R") #replace text in quotes with model to be loaded eg: "3rd_100_R"

#choose your poison

c_n = torch.randn(1, 11) # Second argument is set to the size of the context vector
c_n = c_n.squeeze()
opt.x_new = opt.next(None, c_n)

client_socket.sendall(np.array([1.0], dtype=np.float64))


while 1:

    reward_data = client_socket.recv(64)
    reward = torch.tensor([np.frombuffer(reward_data, dtype=np.float64).tolist()])
    print("reward: ", reward)

    context_data = client_socket.recv(640)
    c_n = torch.tensor(np.frombuffer(context_data, dtype=np.float64).tolist())
    print("context: ", c_n)

    opt.x_new = opt.next(reward, c_n)

    print("x_new: ", opt.x_new)
    tensor_data = opt.x_new.detach().numpy().flatten()
    client_socket.sendall(np.array(tensor_data, dtype=np.float64))








import socket
import numpy as np

TCP_IP = '192.168.178.138'
TCP_PORT = 5000

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((TCP_IP, TCP_PORT))

# Receive data (assuming it's a byte stream)

# Convert the received bytes back to a Python list of doubles
while 1:
    received_data = client_socket.recv(1024)
    double_list1 = np.frombuffer(received_data, dtype=np.float64).tolist()
    print("Received list of doubles:", double_list1)

    received_data = client_socket.recv(1024)
    double_list = np.frombuffer(received_data, dtype=np.float64).tolist()
    print("Received list of doubles:", double_list)

#data_str = ",".join(map(, double_list))

# Send the data to the server
    print(np.array(double_list[0:3]))
    client_socket.send(np.array(double_list[0:3]))
    break



client_socket.close()


def black_box_simple(x,y):
    if x == None or y == None:
        return None
    if x is not torch.Tensor:
        x=torch.tensor((x))
    if y is not torch.Tensor:
        y=torch.tensor((y))
    #print(x.shape,y.shape)
#    if x.shape[0] >=2:
#        x = x[0]
#    x1 = x.item()
#    y1 = y.item()
    #print((1-x**2-y**2).clone().detach().shape)
    return (1-x*x-y*y).clone().detach()


def black_box_complex(x,y):
    if x == None or y == None:
        return None
    if x is not torch.Tensor:
        x=torch.tensor((x))
    if y is not torch.Tensor:
        y=torch.tensor((y))
    return torch.randn(1).clone().detach()

""""p_i = torch.randn(2, 1).clone().detach()
c_i = torch.randn(2, 1).clone().detach()
opt.context = c_i
opt.prev_context = []
opt.x_new = p_i
print(opt.context,opt.x_new)
print(torch.cat([p_i,c_i]),black_box_simple(p_i, c_i))
handler = dh(x=torch.cat([p_i,c_i],1), y=black_box_simple(p_i, c_i))
#handler = dh.from_file("test_data_2d_0.yaml")
opt.data_handler = handler
#print(handler.data.Ys,"Y")
#print(handler.data.Xs,"X",handler.data.Xs.size())
opt.gp = opt._initialize_model(handler)
opt.acq_func = opt._initialize_acqf()

count = 0
for i in range(0,99):
    print(black_box_simple(opt.x_new,opt.context))
    reward = black_box_simple(opt.x_new,opt.context)
    print(reward,"r")
    print(opt.context,"c")
    goal = torch.cat([reward,opt.context],1)
    print(goal,"g")
    print(goal[0],goal[1])
    print(opt.x_new,"x new")
    print(opt.context, "c")
    opt._update_model(goal)
    p_i = opt.get_optimal_parameters()
    opt.x_new = p_i
    count = count + 1
    opt.prev_context = c_i
    if count == 5:
        c_i = torch.randn(2, 1).clone().detach()
        opt.context = c_i
        count = 0
        opt._initialize_acqf()




#print(opt.input_dim)"""

"""
array_to_send = np.array([10, 20, 30, 40, 50], dtype=np.float64)

# Send the length of the array first
array_length = len(array_to_send)
client.sendall(struct.pack('!I', array_length))

# Send the array data
client.sendall(array_to_send.tobytes())

# Read the length of the incoming array
array_length_data = client.recv(4)
array_length = struct.unpack('!I', array_length_data)[0]

# Read the array data
received_data = client.recv(array_length * 8)
received_array = np.frombuffer(received_data, dtype=np.float64)

print("Received array from server:")
print(received_array)
"""








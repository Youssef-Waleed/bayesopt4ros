import matlab.engine as eng
import matlab as mat
import sys
sys.path.append("C:/Users/youse/Downloads/sequential-convex-programming-master/sequential-convex-programming-master/code")


test = eng.start_matlab()
#eng.cd(r'C:/Users/youse/Downloads/sequential-convex-programming-master/sequential-convex-programming-master/code', nargout=0)
s = mat.sqrt(2)
print(s)
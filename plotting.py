import numpy as np
import subprocess
from matplotlib import pyplot as plt

noOfSample = 5

sizeX = [250, 500, 750, 1000, 1250]
sizeY = [250, 500, 750, 1000, 1250]
nodes = [20, 40, 60, 80, 100]
flows = [10, 20, 30, 40, 50]

plotCount = 0

# valueFile = open("value.txt", "w")
          
def getStat(areaIndex, nodeIndex, flowIndex):
    stats = []

    while len(stats) < 4:
        configFile = open("config.txt", "w")
        configFile.write(str(sizeX[areaIndex]) + "\n" + 
                            str(sizeY[areaIndex]) + "\n" + 
                            str(nodes[nodeIndex]) + "\n" + 
                            str(flows[flowIndex]))
        configFile.flush()
        configFile.close()
        subprocess.run(["ns", "wireless.tcl"], stdout=subprocess.DEVNULL)
        stats = subprocess.run(["awk", "-f", "parse.awk", "trace.tr"], stdout=subprocess.PIPE)
        stats = str(stats.stdout).replace("b", "").replace("'", "").split("\\n")
    
    stats.pop()
    return stats

def plotGraph(x, y, xLabel, yLabel):
    y = y.astype(np.float)

    # global valueFile
    # valueFile.write(str(x)+"\n")
    # valueFile.write(str(y)+"\n")

    global plotCount
    plotCount+=1
    plt.figure(plotCount)
    
    plt.plot(x, y, 'ro')
    plt.plot(x, y)
    plt.xlabel(xLabel)
    plt.ylabel(yLabel)
    plt.title(xLabel+" vs "+yLabel)
    plt.grid()

def plotGraphs(x, ys, xLabel):
    ys = np.array(ys)
    ys = ys.transpose()

    plotGraph(x, ys[0], xLabel, "Throughput (bits/sec)")
    plotGraph(x, ys[1], xLabel, "Average Delay (seconds)")
    plotGraph(x, ys[2], xLabel, "Delivery Ratio")
    plotGraph(x, ys[3], xLabel, "Drop ratio")

stats = []
for i in range(noOfSample):
    print(sizeX[i], 40, 20)
    stats.append(getStat(i, 1, 1))
plotGraphs(sizeX, stats, "Area Size (m)")

stats = []
for i in range(noOfSample):
    print(500, nodes[i], 40)
    stats.append(getStat(1, i, 1))
plotGraphs(nodes, stats, "Number of Nodes")

stats = []
for i in range(noOfSample):
    stats.append(getStat(1, 1, i))
plotGraphs(flows, stats, "Number of Flows")

# valueFile.flush()
# valueFile.close()

plt.show()

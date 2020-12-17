namespace import ::tcl::mathfunc::*

# Read onfiguration from file
set configFile [open config.txt r]
gets $configFile sizeX
gets $configFile sizeY
gets $configFile nodeCount
gets $configFile flowCount

# simulator
set ns [new Simulator]


# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy/802_15_4          ;# network interface type
set val(mac)          Mac/802_15_4               ;# MAC type
set val(rp)           DSDV                     ;# ad-hoc routing protocol 
set val(nn)           $nodeCount               ;# number of mobilenodes
# =======================================================================

# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all-wireless $nam_file $sizeX $sizeY

# topology: to keep track of node movements
set topo [new Topography]
$topo load_flatgrid $sizeX $sizeY ;# $sizeX x $sizeY area


# general operation director for mobilenodes
create-god $val(nn)


# node configs
$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace OFF

# create nodes
for {set i 0} {$i < $val(nn) } {incr i} {
    set node($i) [$ns node]
    $node($i) random-motion 1       ;# disable random motion

    $node($i) set X_ [expr [rand] * $sizeX]
    $node($i) set Y_ [expr [rand] * $sizeY]
    $node($i) set Z_ 0

    set nextX [expr [rand] * $sizeX]
    set nextY [expr [rand] * $sizeX]
    set velocity [expr [rand] * 5]

    $ns at 1.0 "$node($i) setdest $nextX $nextY $velocity"

    $ns initial_node_pos $node($i) 20
} 

# Agent/UDP set packetSize_ 50
# Application/Traffic/Exponential set packetSize_ 50

# Traffic
set val(nf)  $flowCount                          ;# number of flows
set src [expr int(floor([rand] * $nodeCount))]

for {set i 0} {$i < $val(nf)} {incr i} {
    set dest $src
    while {[expr $src == $dest]} {
        set dest [expr int(floor([rand] * $nodeCount))]
    }

    # Traffic config
    # create agent
    set udp [new Agent/UDP]
    $udp set class_ 2
    set udp_sink [new Agent/Null]
    # attach to nodes
    $ns attach-agent $node($src) $udp
    $ns attach-agent $node($dest) $udp_sink
    # connect agents
    $ns connect $udp $udp_sink
    $udp set fid_ $i
    # $udp set packetSize_ 110

    # Traffic generator
    set exp [new Application/Traffic/Exponential]
    $exp set packetSize_ 100
    $exp set burst_time_ 500ms
    $exp set idle_time_ 500ms
    $exp set rate_ 1k
    # attach to agent
    $exp attach-agent $udp

    # start traffic generation
    $ns at 1.0 "$exp start"
}

# End Simulation

# Stop nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 50.0 "$node($i) reset"
}

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 50.0001 "finish"
$ns at 50.0002 "halt_simulation"



# Run simulation
puts "Simulation starting"
$ns run


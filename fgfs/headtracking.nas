##
## headtracking.nas
##
##  Nasal code for using an external head position and orientation tracker.
##
##  This file is licensed under the GPL license version 2 or later.
##    Copyright (C) 2007 - 2009  Anders Gidenstam
## 
##  2011 modified by Ralph Glass and Meir Michanie (GPL)
##  

## Installation:
## - Put this file in ~/.fgfs/Nasal
## - Start FlightGear with the parameters
##    --generic=socket,in,<hz>,,<port>,udp,headtrack --prop:/sim/headtracking/enabled=1

##
# Headtracker view handler class.
# Use one instance per headtracked view.
#
var headtracker_view_handler = {
    new : func {
        return { parents: [headtracker_view_handler] };
    },
    init : func {
        if (contains(me, "enabled")) return;

        me.enabled = props.globals.getNode("/sim/headtracking/enabled", 1);
        setprop("/sim/headtracking/factors/pitch-factor",1.5);
        setprop("/sim/headtracking/factors/yaw-factor",2.5); 
        setprop("/sim/headtracking/factors/x-factor",1.5);
        setprop("/sim/headtracking/factors/y-factor",-1.5);
        setprop("/sim/headtracking/factors/z-factor",-1.5);
        setprop("/sim/headtracking/factors/deadzone", 15);
        setprop("/sim/headtracking/zoom-panel", 0);
        setprop("/sim/headtracking/mirror", 0);        
        setprop("/sim/headtracking/factors/yaw-factor-linear", 15);

    		#me.mirror.setValue("-1");
        me.ht_pos_offset =
            props.globals.getNode("/sim/headtracking/position", 1);
        me.ht_rot_offset =
            props.globals.getNode("/sim/headtracking/orientation", 1);

        # Low pass filters.
        me.hoffset_lowpass = aircraft.lowpass.new(0.1);
        me.poffset_lowpass = aircraft.lowpass.new(0.1);

        me.view = props.globals.getNode("/sim/current-view", 1);

	var vn = getprop("/sim/current-view/view-number");
	var vn=0;
        #var me.conf = sprintf("/sim/view[%d]/config", vn);
        me.conf = props.globals.getNode("/sim/view/config");
        #foreach (parm ; ["x-offset-m", "y-offset-m", "z-offset-m"]) {
        #     setprop("/sim/current-view/", parm, getprop(me.conf, parm));
        #}

        print("headtracker_view_manager ... initialized.");
	printf("original x-offset-m=%.1f",asnum(getprop("/sim/view/config/x-offset-m")));
	printf("original y-offset-m=%.1f",asnum(getprop("/sim/view/config/y-offset-m")));
	printf("original z-offset-m=%.1f",asnum(getprop("/sim/view/config/z-offset-m")));
        foreach (parm ; ["x-factor", "y-factor", "z-factor", "yaw-factor", "pitch-factor"]) {
		printf("Factor(%s)=%.1f ",parm,asnum(getprop("/sim/headtracking/factors/",parm)));
    	}
    },
    start : func {
    },
    stop : func {
    },
    reset : func {
        var heading = me.hoffset_lowpass.filter(0);
        var pitch   = me.poffset_lowpass.filter(0);

        me.view.getChild("goal-heading-offset-deg").setValue(heading);
        me.view.getChild("goal-pitch-offset-deg").setValue(pitch);
        me.view.getChild("x-offset-m").setValue(asnum(me.conf.getChild("x-offset-m")));
        me.view.getChild("y-offset-m").setValue(asnum(me.conf.getChild("y-offset-m")));
    },
    update : func {
        if (me.enabled.getValue()) {
            var x = asnum(me.ht_pos_offset.getChild("x-offset-m").getValue());
            var y = asnum(me.ht_pos_offset.getChild("y-offset-m").getValue());
            var z = asnum(me.ht_pos_offset.getChild("z-offset-m").getValue());
            var deadzone = (asnum(getprop("/sim/headtracking/factors/deadzone"))/1000);
            var yawlinear = asnum(getprop("/sim/headtracking/factors/yaw-factor-linear"));
            var yawfactor = getprop("/sim/headtracking/factors/yaw-factor");
            var yawfactorfinal = yawfactor;

            if (x > deadzone) {yawfactorfinal=yawfactor*(x-deadzone)*yawlinear;};
            if (x > 0.1) {x=0.1;}; #{setprop("/sim/headtracking/factors/yaw-factor",x*20);x=0.1;};
            
            if (x < deadzone) {yawfactorfinal=0;};
            if (x < -deadzone) {yawfactorfinal=yawfactor*-(x+deadzone)*yawlinear;};

            if (x < -0.1) {x=-0.1;};
 
            var zoomfactor = 1;
            if (asnum(getprop("/sim/headtracking/zoom-panel"))==1) { if (z > 0.02) { zoomfactor = ((z-0.02)*50)+1;}; };

            var heading =
                me.hoffset_lowpass.filter
                (asnum(me.ht_rot_offset.getChild("heading-deg").getValue()) * yawfactorfinal);
            var pitch   =
                me.poffset_lowpass.filter
                (asnum(me.ht_rot_offset.getChild("pitch-deg").getValue()) * getprop("/sim/headtracking/factors/pitch-factor"));
            var roll    =
                asnum(me.ht_rot_offset.getChild("roll-deg").getValue());

           var oldheading = asnum(me.view.getChild("goal-heading-offset-deg").getValue()); 

           var mirror = 1;
           if (getprop("/sim/headtracking/mirror")==1) { mirror = -1 ;};
            # printf("old heading = %.1f",oldheading);
            # printf("new heading = %.1f",heading);
            # printf("var x       = %.4f",x);
            # printf("var z       = %.4f",z);
           
      
            me.view.getChild("goal-heading-offset-deg").setValue(heading * (1/zoomfactor) * mirror);
            me.view.getChild("goal-pitch-offset-deg").setValue(pitch * mirror);
            me.view.getChild("goal-roll-offset-deg").setValue(roll);

           # setprop("/rendering/scene/ambient/blue",3.0); /// test settings for anaglyph 3d
           # setprop("/rendering/scene/ambient/green",2.0);
           # setprop("/rendering/scene/ambient/red",2.0);

           # me.view.getChild("x-offset-m").setValue(asnum(me.conf.getChild("x-offset-m")) + x);
           # me.view.getChild("y-offset-m").setValue(asnum(me.conf.getChild("y-offset-m")));
           # me.view.getChild("z-offset-m").setValue(asnum(me.conf.getChild("z-offset-m")));

            #me.view.getChild("x-offset-m").setValue(asnum(getprop("/sim/view/config/x-offset-m")) + (* x));
            #me.view.getChild("y-offset-m").setValue(asnum(getprop("/sim/view/config/y-offset-m")) + (* y));
            #me.view.getChild("z-offset-m").setValue(asnum(getprop("/sim/view/config/z-offset-m")) + (* z));
            #me.view.getChild("field-of-view").setValue(55  + z * -500);
            me.view.getChild("x-offset-m").setValue(asnum(getprop("/sim/view/config/x-offset-m")) + (getprop("/sim/headtracking/factors/x-factor") * x ));
            me.view.getChild("y-offset-m").setValue(asnum(getprop("/sim/view/config/y-offset-m")) + (getprop("/sim/headtracking/factors/y-factor") * y ) - (0.1*((zoomfactor)-1)) - 0.05);
            me.view.getChild("z-offset-m").setValue(asnum(getprop("/sim/view/config/z-offset-m")) + (getprop("/sim/headtracking/factors/z-factor") * z * zoomfactor));
        }
#        print("Tracker position: (" ~
#              asnum(me.ht_pos_offset.getChild("x-offset-m").getValue()) ~" " ~
#              asnum(me.ht_pos_offset.getChild("y-offset-m").getValue()) ~" " ~
#              asnum(me.ht_pos_offset.getChild("z-offset-m").getValue()) ~")");
        return 0;
    }
};

var asnum = func(n) {
    if(typeof(n) == "scalar") {
        return num(n);
    } else {
        return 0;
    }
}

if (getprop("/sim/headtracking/enabled")) {
    if (view.indexof("Cockpit View") != nil)
        view.manager.register("Cockpit View", headtracker_view_handler);
    if (view.indexof("Pilot View") != nil)
        view.manager.register("Pilot View", headtracker_view_handler);
    if (view.indexof("Copilot View") != nil)
        view.manager.register("Copilot View", headtracker_view_handler);
}

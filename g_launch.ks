CLEARSCREEN.



// ****************************************************************
//FUNCTIONS
// ****************************************************************
run once lib.


// ****************************************************************
// Variables.
// ****************************************************************
set orbitalInclination to 90.0.
set orbitalHeight to 100000. // Default is 100k.  
set attemptReentry to true.
set initialPitchOverDeg to 20 . // 20 for 2.x twr// vary this based on steering capiblities of rocket
set pitchOverSpeed to 25. // 25 for 2.x twr. // m/s , vary based on TWR of rocket.  Higher thrust to weight should tip over quicker, notes below:
//The tweakables you have then is then is how long you wait until starting the pitch over and how sharply you pitch over. Apply some heuristics to that. For low TWR rockets you'll want to rise more and do less of a pitch over. For high TWR rockets you'll want to pitch over sooner and more sharply.

//You may want to add some maximum AoA limiting to the initial pitch over to prevent rockets flipping if you want to do fairly violent pitch overs for very high TWR rockets (or add fins).

//Generally to optimize your launches you'll just want to build rockets with higher TWR and pitch over as hard as you can without your rocket failing to make orbit (gravity losses are generally always worse than drag losses for post-KSP-1.0 atmospheres).



//Next, we'll lock our throttle to x%. depending on solid fuel boosters
//TODO: make this more intelligent based off of the thrust to weight ratio of the rocket
set idealTWR to 2.
set curThrottle to choose 1 if stage:solidfuel else 1.0.   // 1.0 is the max, 0.0 is idle.
lock throttle to curThrottle.

//find any solid boosters. used to monitor fuel.
LIST ENGINES IN engineList.
FOR eng IN engineList {
    if eng:name = "solidBooster1-1" or eng:name="MassiveBooster" {
        print "Solid Boosters Detected, changing thrust profile".
        set solidEngine to eng.
    }
}.


//This is our countdown loop, which cycles from 3 to 0
PRINT "Counting down:".
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    // if countdown <= 1 {
    //     // print "igniting Engines".
    //     stage.
    // }
    WAIT 1. // pauses the script here for 1 second.
}


//Simple staging code. Will only trigger when the stage is completly out of thrust.  
// Will work until
WHEN MAXTHRUST = 0 and periapsis < orbitalHeight THEN {
    if velocity:surface:mag > 50 {lock throttle to 0.}.
    
    PRINT "Staging".
    STAGE.
    if velocity:surface:mag > 50 {
        wait 1. 
        lock throttle to 1.
    }
    PRESERVE.
}.




set desiredPitch to 90.
set curDirection TO HEADING(orbitalInclination,desiredPitch). //90 degrees east and pitched up 90 degrees (straight up)
LOCK STEERING TO curDirection. // from now on we'll be able to change steering by just assigning a new value to MYSTEER


when (ship:velocity:surface:mag > pitchOverSpeed and pitch_of_vector(ship:velocity:surface) <= (90-initialPitchOverDeg)) then {
    print "Following Gravity".
        lock steering to ship:velocity:surface.
}

when (ship:velocity:surface:mag > pitchOverSpeed and pitch_of_vector(ship:velocity:surface) > (90-initialPitchOverDeg)) then {
        print "Pitching to: ".
        set desiredPitch to 90 - initialPitchOverDeg.  
        set curDirection to heading(orbitalInclination, desiredPitch).
        print heading(orbitalInclination, desiredPitch).
        
    }

UNTIL APOAPSIS > orbitalHeight + 2_000 {
    print_stats().

    // Solid booster ejection
    if ( stage:solidfuel ) {
        //Get the solid fuel remaining, to check to see if we need to prepare to stage.  
        local solidFuelRemaining to solidEngine:CONSUMEDRESOURCES:values[0]:amount / solidEngine:CONSUMEDRESOURCES:values[0]:capacity.
        if(solidFuelRemaining < 0.05 and solidEngine:flameout = false) {
            print "Preparing to stage solid boosters".
            lock throttle to 1.0.
            // set curDirection to ship:velocity:surface:normalized.
            
            wait until solidEngine:flameout.
            // wait 2.
            print "Staging solid boosters".
            stage.
            wait 2.
            // set post solid booster throttle control, should switch to get next throttle func?.  
            // if is to prevent divide by 0.  
            if (ship:availablethrust > 0 ) {
                set curThrottle to  min(idealTWR * Ship:Mass * get_g() / Ship:AvailableThrust, 1).
            }
        }
    }

    
}
lock steering to heading(orbitalInclination, 3).
if (attemptReentry) {
    print "Staging for reentry".
    stage.
}
when APOAPSIS > orbitalHeight then {
    PRINT "Orbital Apoapsis reached, cutting engines".
    
    lock throttle to 0.
    //remove below when we want to get the most out of the launch booster
    print "Stage now if you want to return the first stage to Kerbin".
    // stage.
}.
wait 5.
warpTo(time:seconds + eta:apoapsis - 35).
wait until ETA:apoapsis < 30.


if(attemptReentry) {
    // Landing cpu stage logic
    when ship:verticalspeed < 0 then {
        print "Preparing for reentry".
        lock steering to velocity:surface:direction:inverse.
    }
    wait until ship:verticalspeed < 0.
    when altitude < 4000 then {
        if(ship:availablethrust > 0){
            print "Firing thrusters to hover".
            lock throttle to 1 * Ship:Mass * get_g() / Ship:AvailableThrust.
        }else {
            print "No fuel, crashing".
        }
    }
    wait until altitude <1000.
} else {

    print "Circularizing orbit".
    // Circulize orbit.
    wait until ETA:apoapsis < 20. 
    Lock STEERING to HEADING(orbitalInclination,3).
    lock throttle to 1.


    wait until periapsis > orbitalHeight.

    clearScreen.
    PRINT "Circular orbit reached".
    print "APOAPSIS: ".
    print apoapsis.
    print "PERIAPSIS".
    print periapsis.
// }
}

LOCK THROTTLE TO 0.

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "Returning Control to Pilot".
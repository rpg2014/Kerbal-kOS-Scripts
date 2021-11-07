//hellolaunch

//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.


// ****************************************************************
//FUNCTIONS
// ****************************************************************
function print_stats {.
  print "APOAPSIS: " at (0,16).
  print apoapsis at (10,16).
  print "VELOCITY: " at (0,17).
  print velocity:surface:mag at (10, 17).
  print "ALTITUDE: " at (0, 18).
  print altitude at (10,18).
  print "PITCH: " at (0,19).
  print pitch_for(ship) at (7,19).

  if (ship:availablethrust > 0 ) {
    print "THROTTLE: " at (0, 21).
    print round(get_next_throttle(2),4) at (10,21).
    print "A_g" at (0,22).
    print get_g() at (4, 22).
    print "Current TWR: " at (0, 23).
    print round(get_TWR(),4) at (13,23).
    print "diff from ideal TWR" at (0,24).
    print (1-((get_TWR() -2) / 2  )) at (21, 24).

    print "Other throttle eq" at (0,25).
    print 2 * Ship:Mass * get_g() / Ship:AvailableThrust at (19, 25).
  }

}
function type_to_vector {
  parameter ves,thing.
  if thing:istype("vector") {
    return thing:normalized.
  } else if thing:istype("direction") {
    return thing:forevector.
  } else if thing:istype("vessel") or thing:istype("part") {
    return thing:facing:forevector.
  } else if thing:istype("geoposition") or thing:istype("waypoint") {
    return (thing:position - ves:position):normalized.
  } else {
    print "type: " + thing:typename + " is not recognized by lib_navball".
  }
}

function pitch_for {
  parameter ves is ship,thing is "default".

  local pointing is ves:facing:forevector.
  if not thing:istype("string") {
    set pointing to type_to_vector(ves,thing).
  }

  return 90 - vang(ves:up:vector, pointing).
}
function get_g {
    local a_g to (constant:g * kerbin:mass) / (altitude + kerbin:radius)^2.
    return a_g.
}
function get_TWR {

    if (ship:availablethrust > 0 ) {
        set curTWR to ship:availableThrust / (ship:mass * get_g()).
        return curTWR.
    }
    else {
        return 0.0.
    }
}



function get_next_throttle {
    parameter desiredTWR.
    local curTWR to get_TWR().

    set throttle_scaling to 1.
    
    if (ship:availablethrust > 0 ) {
        local differenceFromIdealTWR to 1-((curTWR -desiredTWR) / desiredTWR  ).
        local nextThrottle to ((throttle_scaling * (differenceFromIdealTWR)) * availableThrust) / maxThrust.

        // local nextThrottle to (1-differenceFromIdealTWR)

        return nextThrottle.
    } else {
        return 0.0.
    }
}

// ****************************************************************
// Variables.
// ****************************************************************
set orbitalInclination to 190.0.

//Next, we'll lock our throttle to x%. depending on solid fuel boosters
//TODO: make this more intelligent based off of the thrust to weight ratio of the rocket
set idealTWR to 2.
set curThrottle to choose 1 if stage:solidfuel else 1.0.   // 1.0 is the max, 0.0 is idle.
lock throttle to curThrottle.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    // if countdown <= 1 {
    //     // print "igniting Engines".
    //     stage.
    // }
    WAIT 1. // pauses the script here for 1 second.
}



// Staging code, shouldn't be used to often, as solid boosters do most of the work.  
WHEN MAXTHRUST = 0 and periapsis < 80_000 THEN {
    if velocity:surface:mag > 50 {lock throttle to 0.}.
    
    PRINT "Staging".
    STAGE.
    if velocity:surface:mag > 50 {
        wait 1. 
        lock throttle to 1.
    }
    PRESERVE.
}.

if(stage:solidFuel) {
    print "Solid Boosters detected".
}


//find any solid boosters. used to monitor fuel.
LIST ENGINES IN engineList.
FOR eng IN engineList {
    if eng:name = "solidBooster1-1" or eng:name="MassiveBooster" {
        set solidEngine to eng.
    }
}.




SET curDirection TO HEADING(orbitalInclination,90). //90 degrees east and pitched up 90 degrees (straight up)
LOCK STEERING TO curDirection. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
set desiredPitch to 90.

UNTIL APOAPSIS > 100000 {
    print_stats().
    SET curDirection TO HEADING(orbitalInclination,desiredPitch).

    set curThrottle to get_next_throttle(idealTWR).

    if stage:solidfuel {
        set solidFuelRemaining to solidEngine:CONSUMEDRESOURCES:values[0]:amount / solidEngine:CONSUMEDRESOURCES:values[0]:capacity.
    }

//    // on use if trying to return the booster 
//     if(stage.liquidfuel > 0){
//         if(stage:liquidFuel  < 150) {
//             print "ditching stage for reentry".
//             stage.
//         }
//     }

    // Solid booster ejection
    if ( stage:solidfuel and solidFuelRemaining < 0.05 and solidEngine:flameout = false) {
        print "Preparing to stage solid boosters".
        lock throttle to 1.0.
        set curDirection to ship:velocity:surface:normalized.
        
        wait until solidEngine:flameout.
        wait 2.
        print "Staging solid boosters".
        stage.
        wait 2.
        // Post solid posster throttle control, should switch to get next throttle
        if (ship:availablethrust > 0 ) {
            set curThrottle to  min(idealTWR * Ship:Mass * get_g() / Ship:AvailableThrust, 1)..
        }

    // Below is the gravity turn.
    // want to change to this equation,
    // beta = current angle between velocy veector and the vertical. beta = arccos()
    // a = g(thrustToWeight - cos(beta))
    } else IF SHIP:VELOCITY:SURFACE:MAG < 50 {
        //This sets our steering 90 degrees up and yawed to the compass
        //heading of 90 degrees (east)
        set desiredPitch to 90.
    //Once we pass 100m/s, we want to pitch down ten degrees
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 50 AND SHIP:VELOCITY:SURFACE:MAG < 150 {
        set desiredPitch to 80.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 150 AND SHIP:VELOCITY:SURFACE:MAG < 300 {
        set desiredPitch to 70.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 300 AND SHIP:VELOCITY:SURFACE:MAG < 400 {
        set desiredPitch to 60.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 400 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        set desiredPitch to 50.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 600 {
        set desiredPitch to 40.
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 600 AND SHIP:VELOCITY:SURFACE:MAG < 700 {
        set desiredPitch to 30.

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 700 AND SHIP:VELOCITY:SURFACE:MAG < 800 {
        set desiredPitch to 20.

    //Beyond 800m/s, we can keep facing towards 10 degrees above the horizon and wait
    //for the main loop to recognize that our apoapsis is above 100km
    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 800 {
        set desiredPitch to 15.
    }.
}.

when APOAPSIS > 100_000 then {
    PRINT "100km apoapsis reached, locking heading direction".
    Lock STEERING to ship:velocity:surface:direction.
    lock throttle to 0.
    //remove below when we want to get the most out of the launch booster
    print "Stage now if you want to return the first stage to Kerbin".
    // stage.
}.





// if we are still using the cpu stage to orbit
// if stage:number <= 1 {
    print "Circularizing orbit".
    // Circulize orbit.
    wait until ETA:apoapsis < 15. 
    Lock STEERING to HEADING(90,0).
    lock throttle to 1.


    wait until periapsis > 80_000.


    PRINT "Circular orbit reached".
    print "APOAPSIS: ".
    print apoapsis.
    print "PERIAPSIS".
    print periapsis.
// }

// if the cpu is on the first stage, then lock in a retrograde direction.
if(stage:number <= 1) {
when ship:verticalspeed < 0 then {
    print "Preparing for reentry".
    lock steering to velocity:surface:direction:inverse.
}
wait until ship:verticalspeed < 0.
} else {
    {
    print "Circularizing orbit".
    // Circulize orbit.
    wait until ETA:apoapsis < 15. 
    Lock STEERING to HEADING(90,0).
    lock throttle to 1.


    wait until periapsis > 80_000.


    PRINT "Circular orbit reached".
    print "APOAPSIS: ".
    print apoapsis.
    print "PERIAPSIS".
    print periapsis.
// }
}


//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.

//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
print "Returning Control to Pilot".
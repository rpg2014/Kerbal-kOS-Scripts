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
FUNCTION pitch_of_vector { // pitch_of_vector returns the pitch of the vector(number range -90 to  90)
    PARAMETER vecT.

    RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}
function pitch_for {
  parameter ves is ship,thing is "default".

  local pointing is ves:facing:forevector.
  if not thing:istype("string") {
    set pointing to type_to_vector(ves,thing).
  }

  return 90 - vang(ves:up:vector, pointing).
}

function print_stats {.
  print "APOAPSIS: " at (0,16).
  print apoapsis at (10,16).
  print "VELOCITY: " at (0,17).
  print velocity:surface:mag at (10, 17).
  print "ALTITUDE: " at (0, 18).
  print altitude at (10,18).
  print "PITCH: " at (0,19).
  print pitch_for(ship) at (7,19).
  print "Pitch for V Vector" at (0,20).
  print 90 - pitch_of_vector(ship:velocity:surface) at (20,20).

//   if (ship:availablethrust > 0 ) {
//     print "THROTTLE: " at (0, 21).
//     print round(get_next_throttle(2),4) at (10,21).
//     print "A_g" at (0,22).
//     print get_g() at (4, 22).
//     print "Current TWR: " at (0, 23).
//     print round(get_TWR(),4) at (13,23).
//     print "diff from ideal TWR" at (0,24).
//     print (1-((get_TWR() -2) / 2  )) at (21, 24).

//     print "Other throttle eq" at (0,25).
//     print 2 * Ship:Mass * get_g() / Ship:AvailableThrust at (19, 25).
//   }
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
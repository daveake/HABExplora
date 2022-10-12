unit HABTypes;

interface

uses Classes, Generics.Collections;

type
  TFieldType = (ftPayloadID, ftCounter,
                ftTimeStamp, ftLatitude, ftLongitude, ftAltitude, ftSpeed, ftHeading, ftSatellites,                     // GPS
                ftTempInt, ftTempExt, ftPressure, ftHumidity,                                                           // Sensors
                ftCDA, ftPredLat, ftPredLong, ftPredLanding, ftPredTime,                                                // Parachute and prediction
                ftLastMessage,                                                                                          // Last uplink message
                ftPitch, ftRoll, ftCompass,                                                                             // 9DOF
                ftTargetHeading, ftRelativeHeading,
                ftDistanceToTarget, ftDistanceToPrediction, ftPredictionToTarget,
                ftTargetAirspeed, ftEstimatedAirspeed, ftAirDirection, ftCrosswind,                                     // Targetting
                ftServoX, ftServoY, ftServoLeft, ftServoRight, ftServoTime,                                             // Servos
                ftGlideRatio,                                                                                           // Gliding
                ftFlightMode,                                                                                           // Flight Mode
                ftCutdownStatus1, ftCutdownSupply, ftCutdownSense1, ftCutdownStatus2, ftCutdownSense2,                  // Cutdown
                ftAngleOfApproach, ftGroundAirSpeed, ftGroundAirDirection,ftLandingDirection);                          // Parafoil


type
  TFieldList = Array of TFieldType;

type
  TValueList = Array of String;

type
  TSettings = TDictionary<String, Variant>;

type
  TExtraFields = TDictionary<String, Variant>;

type
  TSignalValues = TDictionary<String, Variant>;

type
  THABPosition = record
    InUse:          Boolean;
    Channel:        Integer;

    // Fields we know about
    PayloadID:          String;                 // Always first field
    Counter:            Integer;                // sentence_id
    TimeStamp:          TDateTime;              // time
    Latitude:           Double;                 // latitude
    Longitude:          Double;                 // longitude
    Altitude:           Double;                 // altitude
    Speed:              Double;                 // speed
    Heading:            Double;                 // heading
    Satellites:         Integer;                // satellites
    TempInt:            Double;                 // temperature_internal
    TempExt:            Double;                 // temperature_external
    Pressure:           Double;                 // pressure
    Humidity:           Double;                 // humidity
    CDA:                Double;                 // cda
    PredLat:            Double;                 // pred_lat
    PredLong:           Double;                 // pred_long
    PredLanding:        Double;                 // pred_land_sp
    PredTime:           Integer;                // pred_time
    LastMessage:        String;                 // last_message
    Pitch:              Double;                 // pitch
    Roll:               Double;                 // roll
    Compass:            Double;                 // compass_heading
    TargetHeading:      Double;                 // target_heading
    RelativeHeading:    Double;                 // relative_heading
    DistanceToTarget:   Double;
    DistanceToPrediction: Double;
    PredictionToTarget: Double;
    TargetAirspeed:     Double;                 // target_airspeed
    EstimatedAirspeed:  Double;                 // est_airspeed
    AirDirection:       Double;                 // air_direction
    Crosswind:          Double;                 // crosswind
    ServoX:             Integer;                // servo_x
    ServoY:             Integer;                // servo_y
    ServoLeft:          Integer;                // servo_left
    ServoRight:         Integer;                // servo_right
    ServoTime:          Integer;                // servo_time
    GlideRatio:         Double;                 // glide_ratio
    FlightMode:         Integer;                // flight_mode
    CutdownStatus1:     Integer;                // cutdown_status
    CutdownStatus2:     Integer;                // cutdown_status
    CutdownSupply:      Double;                 // cutdown_supply
    CutdownSense1:       Double;                 // cutdown_1
    CutdownSense2:       Double;                 // cutdown_1
    UplinkCount:        Integer;                // uplink_count
    RepeatCount:        Integer;                // repeat_count
    AngleOfApproach:    Integer;
    GroundAirSpeed:     Double;
    GroundAirDirection: Integer;
    LandingDirection:   Integer;

    // Fields we don't know about
    ExtraFields:    TExtraFields;

    // Signal information from the receiver
    SignalValues:   TSignalValues;

    // SSDV
    SSDVPacket:     String;

    // Field list and values
    FieldList:      TFieldList;
    FieldValues:    TValueList;
  end;

type
  TSourcePositionCallback = procedure(ID: Integer; Connected: Boolean; Line: String; Position: THABPosition) of object;

implementation

end.


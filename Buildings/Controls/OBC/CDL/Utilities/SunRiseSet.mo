within Buildings.Controls.OBC.CDL.Utilities;
block SunRiseSet "Next sunrise and sunset time"
  parameter Modelica.Units.SI.Angle lat(displayUnit="deg") "Latitude";
  parameter Modelica.Units.SI.Angle lon(displayUnit="deg") "Longitude";
  parameter Modelica.Units.SI.Time timZon(displayUnit="h") "Time zone";

  Interfaces.RealOutput nextSunRise(
    final quantity="Time",
    final unit="s",
    displayUnit="h") "Time of next sunrise"
    annotation (Placement(transformation(extent={{100,40},{140,80}})));
  Interfaces.RealOutput nextSunSet(
    final quantity="Time",
    final unit="s",
    displayUnit="h") "Time of next sunset"
    annotation (Placement(transformation(extent={{100,-20},{140,20}})));
  Interfaces.BooleanOutput sunUp "Output true if the sun is up"
    annotation (Placement(transformation(extent={{100,-80},{140,-40}})));
protected
  constant Real k1 = sin(23.45*2*Modelica.Constants.pi/360) "Intermediate constant";
  constant Real k2 = 2*Modelica.Constants.pi/365.25 "Intermediate constant";

  parameter Modelica.Units.SI.Time staTim(fixed=false) "Simulation start time";

  Modelica.Units.SI.Time eqnTim "Equation of time";
  Modelica.Units.SI.Time timDif "Time difference between local and civil time";
  Modelica.Units.SI.Time timCor "Time correction";
  Modelica.Units.SI.Angle decAng "Declination angle";
  Real Bt "Intermediate variable to calculate equation of time";
  Real cosHou "Cosine of hour angle";

  function nextHourAngle "Calculate the hour angle when the sun rises or sets next time"
    input Modelica.Units.SI.Time t "Current simulation time";
    input Modelica.Units.SI.Angle lat "Latitude";
    output Modelica.Units.SI.Angle houAng "Solar hour angle";
    output Modelica.Units.SI.Time tNext
      "Timesnap when sun rises or sets next time";
    output Modelica.Units.SI.Time timCor "Time correction";
  protected
    Integer iDay;
    Boolean compute "Flag, set to false when the sun rise or sets ";
    Real Bt "Intermediate variable to calculate equation of time";
    Modelica.Units.SI.Time eqnTim "Equation of time";
    Modelica.Units.SI.Time timDif "Time difference";
    Modelica.Units.SI.Angle decAng "Declination angle";
    Real cosHou "Cosine of hour angle";
  algorithm
    iDay := 1;
    compute := true;
    while compute loop
      tNext := t+iDay*86400;
      Bt := Modelica.Constants.pi*((tNext + 86400)/86400 - 81)/182;
      eqnTim := 60*(9.87*Modelica.Math.sin(2*Bt) - 7.53*Modelica.Math.cos(Bt) -
                1.5*Modelica.Math.sin(Bt));
      timCor := eqnTim + timDif;
      decAng := Modelica.Math.asin(-k1*Modelica.Math.cos((tNext/86400 + 10)*k2));
      cosHou := -Modelica.Math.tan(lat)*Modelica.Math.tan(decAng);
      compute := abs(cosHou) > 1;
      iDay := iDay + 1;
    end while;
    houAng := Modelica.Math.acos(cosHou);
  end nextHourAngle;

  function sunRise "Output the next sunrise time"
    input Modelica.Units.SI.Time t "Current simulation time";
    input Modelica.Units.SI.Time staTim "Simulation start time";
    input Modelica.Units.SI.Angle lat "Latitude";
    output Modelica.Units.SI.Time nextSunRise;
  protected
    Modelica.Units.SI.Angle houAng "Solar hour angle";
    Modelica.Units.SI.Time tNext "Timesnap when sun rises next time";
    Modelica.Units.SI.Time timCor "Time correction";
    Modelica.Units.SI.Time sunRise "Sunrise of the same day as input time";
    Real cosHou "Cosine of hour angle";
  algorithm
    (houAng,tNext,timCor) := nextHourAngle(t, lat);
    sunRise :=(12 - houAng*24/(2*Modelica.Constants.pi) - timCor/3600)*3600 +
               floor(tNext/86400)*86400;
    //If simulation start time has passed the sunrise of the initial day, output
    //the sunrise of the next day.
    if staTim > sunRise then
      nextSunRise := sunRise + 86400;
    else
      nextSunRise := sunRise;
    end if;
  end sunRise;

  function sunSet "Output the next sunset time"
    input Modelica.Units.SI.Time t "Current simulation time";
    input Modelica.Units.SI.Time staTim "Simulation start time";
    input Modelica.Units.SI.Angle lat "Latitude";
    output Modelica.Units.SI.Time nextSunSet;
  protected
    Modelica.Units.SI.Angle houAng "Solar hour angle";
    Modelica.Units.SI.Time tNext "Timesnap when sun sets next time";
    Modelica.Units.SI.Time timCor "Time correction";
    Modelica.Units.SI.Time sunSet "Sunset of the same day as input time";
    Real cosHou "Cosine of hour angle";
  algorithm
    (houAng,tNext,timCor) := nextHourAngle(t, lat);
    sunSet :=(12 + houAng*24/(2*Modelica.Constants.pi) - timCor/3600)*3600 +
              floor(tNext/86400)*86400;
    //If simulation start time has passed the sunset of the initial day, output
    //the sunset of the next day.
    if staTim > sunSet then
      nextSunSet := sunSet + 86400;
    else
      nextSunSet := sunSet;
    end if;
  end sunSet;

initial equation
  staTim = time;
  nextSunRise = sunRise(time-86400,staTim,lat);
  //In the polar cases where the sun is up during initialization, the next sunset
  //actually occurs before the next sunrise
  if cosHou < -1 then
    nextSunSet = sunSet(time-86400,staTim,lat) - 86400;
  else
    nextSunSet = sunSet(time-86400,staTim,lat);
  end if;

equation
  Bt = Modelica.Constants.pi*((time + 86400)/86400 - 81)/182;
  eqnTim = 60*(9.87*Modelica.Math.sin(2*Bt) - 7.53*Modelica.Math.cos(Bt) - 1.5*
          Modelica.Math.sin(Bt));
  timDif = lon*43200/Modelica.Constants.pi - timZon;
  timCor = eqnTim + timDif;
  decAng = Modelica.Math.asin(-k1*Modelica.Math.cos((time/86400 + 10)*k2));
  cosHou = -Modelica.Math.tan(lat)*Modelica.Math.tan(decAng);

  //When time passes the current sunrise/sunset, output the next sunrise/sunset
  when time >= pre(nextSunRise) then
    nextSunRise = sunRise(time,staTim,lat);
  end when;

  when time >= pre(nextSunSet) then
    nextSunSet = sunSet(time,staTim,lat);
  end when;

  sunUp = nextSunSet < nextSunRise;

annotation (defaultComponentName="sunRiseSet",
  Documentation(info="<html>
<p>
This block outputs the next sunrise and sunset time.
The sunrise time keeps constant until the model time reaches the next sunrise,
at which time the output gets updated.
Similarly, the output for the next sunset is updated at each sunset.
</p>
<p>
The time zone parameter is based on UTC time; for instance, Eastern Standard Time is -5h.
Note that daylight savings time is not considered in this component.
</p>
<h4>Validation</h4>
<p>
A validation can be found at
<a href=\"modelica://Buildings.Controls.OBC.CDL.Utilities.Validation.SunRiseSet\">
Buildings.Controls.OBC.CDL.Utilities.Validation.SunRiseSet</a>.
</p>
</html>",
revisions="<html>
<ul>
<li>
November 27, 2018, by Kun Zhang:<br/>
First implementation.
This is for
issue <a href=\"https://github.com/lbl-srg/modelica-buildings/issues/829\">829</a>.
</li>
</ul>
</html>"),
Icon(graphics={  Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid),
          Text(
            extent={{-100,160},{100,106}},
            lineColor={0,0,255},
            textString="%name"),
          Ellipse(
            extent={{70,-100},{-70,20}},
            lineColor={238,46,47},
            startAngle=0,
            endAngle=180),
          Line(
            points={{-94,-40},{92,-40},{92,-40}},
            color={28,108,200},
            thickness=0.5),
          Line(points={{0,60},{0,32}}, color={238,46,47}),
          Line(points={{60,40},{40,20}}, color={238,46,47}),
          Line(points={{94,-6},{70,-6}}, color={238,46,47}),
          Line(
            points={{10,10},{-10,-10}},
            color={238,46,47},
            origin={-50,30},
            rotation=90),
          Line(points={{-70,-6},{-94,-6}}, color={238,46,47})}));
end SunRiseSet;

within Buildings.Utilities.IO.SignalExchange.HaystackTags;
type DuctSectionType = enumeration(
    None
      "No tag",
    discharge
      "discharge",
    economizer
      "economizer",
    exhaust
      "exhaust",
    flue
      "flue",
    inlet
      "inlet",
    mixed
      "mixed",
    outside
      "outside",
    return_t
      "return",
    ventilation
      "ventilation") "Markers for ductSectionType"
  annotation ();

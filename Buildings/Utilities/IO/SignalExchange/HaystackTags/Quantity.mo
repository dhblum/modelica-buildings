within Buildings.Utilities.IO.SignalExchange.HaystackTags;
type Quantity = enumeration(
    None
      "No tag",
    temp
      "temp",
    flow_t
      "flow",
    pressure
      "pressure",
    humidity
      "humidity",
    power
      "power",
    concentration
      "concentration") "Markers for quantity"
  annotation ();

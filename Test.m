
saxsi = SAXSiClass();
[success, containsMask] = saxsi.LoadCalibration('', 0);
[success] = saxsi.LoadMask('');

saxsi.LoadIntegrationOptions('');

saxsi.IntegrationOptions.BinCount = 100;

saxsi.Integrate('');

1;


function [majorNumber, minorNumber, shortText, longText] = GetVersion()
    majorNumber = 1;
    minorNumber = 9.3;
    shortText = sprintf('SAXSi %g.%g (Sep 6th 2017)', majorNumber, minorNumber);
    longText = shortText;
end

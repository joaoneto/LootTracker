Log = {};

Log.Error = function( context, ... )
	local output = string.format ("<rgb=#999999>(%s)</rgb> <rgb=#FF0000>%s</rgb>", context or "", table.concat( arg ) );
	Turbine.Shell.WriteLine( output );
end

Log.Debug = function( context, ...)
	local output = string.format ("<rgb=#999999>(%s)</rgb> <rgb=#FF00FF>%s</rgb>", context or "", table.concat( arg ) );
	Turbine.Shell.WriteLine( output );
end

package;

import haxe.io.Input;
import neko.Lib;
import sys.io.File;
import sys.io.FileInput;

/**
 * ...
 * @author Vincent Blanchet
 */
class Main 
{
	
	static function main() 
	{
		if (Sys.args().length == 0 )
			Sys.println("neko po-lang-switcher: missing file arguments\nTry 'neko po-lang-switcher --help' for more information.");
		else if (Sys.args()[0] == "--help")
		{
			
			Sys.println("Usage : neko po-lang-switcher PATH-TO-.PO-FILE [OVERRIDE]");
			Sys.println("Read .po file and switch language in code. Code file are duplicated with '.trad' extension, WARNING : if OVERRIDE is 'true' then code file are overriden be sure to save before");
			Sys.println("A new po file is created with '.trad' in extension.");
		}else {
			
			var poPath = Sys.args()[0];
			var overrideFile:Bool = (Sys.args().length == 2 && Sys.args()[1].toLowerCase() == "true");
			var poReader = null;
			
			//treat current po file
			try{
			poReader = new PoReader(poPath,overrideFile);// "../test/tchat/lang/en.po");
			}catch (e:Dynamic) {
				Sys.println("Error while parsing po file:");
				Sys.println(e);
				return;
			}
			
			//show report
			Sys.println(poReader.report());
			
			//save new po file
			try{
			File.saveContent(poPath + ".trad", poReader.res);
			}catch (e:Dynamic) {
				Sys.println("Error while saving po file:");
				Sys.println(e);
			}
			
			//save duplicated
			try{
			File.saveContent(poPath + ".duplicated", poReader.duplicated);
			}catch (e:Dynamic) {
				Sys.println("Error while saving duplicated file:");
				Sys.println(e);
			}
			
			Sys.println("Completed.");
			
		}
	}	
}
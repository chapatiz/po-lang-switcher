package;
import haxe.io.Eof;
import haxe.io.Input;
import sys.io.File;

/**
 * Parse po file and treat each traduction block
 * @author Vincent Blanchet
 */
class PoReader
{
	var po:Input;
	var line:String;
	var fc:String;//first char of line
	var basePath:String;
	var poDir:String;

	public var res:String;
	
	public function new(path:String,overrideFile:Bool) 
	{
		var tmp = path.split("/");
		tmp.pop();
		poDir = tmp.join("/") + "/";
		
		res = "";
		try{
			po = File.read(path);	
		}catch (e:Dynamic) {
			throw("file " + path + " not found");
		}
		parseHeader();
		parseTrad(overrideFile);
		po.close();
	}
	
	function parseHeader()
	{
		do{
			line = po.readLine();
			var basePathEx = ~/"X-Poedit-Basepath: (.*)\\n"/;
			if (basePathEx.match(line))
			{
				basePath = poDir+basePathEx.matched(1);
				trace("basePath:" + basePath);
			}
			fc = line.charAt(0);
			res += line+"\n";
			//trace(line);
		}while (fc == "m" || fc == "\"");
		trace("header parsed");
	}
	
	function parseTrad(overrideFile:Bool):Void
	{
		var tb = new TradBlock(basePath);
		var cpt = 0;
		do{
			var msgidExp = ~/msgid "(.*)"/i;
			var msgstrExp = ~/msgstr "(.*)"/i;
			try{
			line = po.readLine();
			}catch (e:Dynamic) {
				if (Std.string(e) == "Eof")
				{
					trace("end of file");
				}
				break;
			}
			if (line.substr(0, 2) == "#:")
			{
				//trace(line);
				tb.addLocation(line.substr(3));
			}else if ( msgidExp.match(line))
			{
				tb.msgid = msgidExp.matched(1);
				if (tb.msgid == "")
					tb = new TradBlock(basePath);
			}else if ( msgstrExp.match(line))
			{
				tb.msgstr = msgstrExp.matched(1);
				tb.run(overrideFile);
				cpt++;

				res += tb.toReverseString();
				res += "\n";
				tb = new TradBlock(basePath);
			}else {
				//trace("no matching:" + line);
				res += line+"\n";
			}
		}while (line != null);
			
	}
	
}
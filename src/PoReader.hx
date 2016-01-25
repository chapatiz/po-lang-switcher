package;
import haxe.ds.StringMap;
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
	var msgstrMap:StringMap<TradBlock>;
	var cpt:Int;

	public var res:String;
	public var duplicated:String;
	
	public function new(path:String,overrideFile:Bool) 
	{
		var tmp = path.split("/");
		tmp.pop();
		poDir = tmp.join("/") + "/";
		msgstrMap = new StringMap<TradBlock>();
		
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
	
	/**
	 * parse and write header to res string
	 */
	function parseHeader()
	{
		do{
			line = po.readLine();
			var basePathEx = ~/^"X-Poedit-Basepath: (.*)\\n"/;
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
	
	/**
	 * find translation block and change code files
	 * @param	overrideFile
	 */
	function parseTrad(overrideFile:Bool):Void
	{
		var status = "normal";
		var tb = new TradBlock(basePath);
		cpt = 0;
		
		
		do {
			var referenceExp = ~/^#: (.*)/i;//find #: something
			var translatorCommentExp = ~/^# (.*)/i;//find # something
			var extractedCommentExp = ~/^#\. (.*)/i;//find #. something
			var msgidExp = ~/^msgid "(.*)"/i;//find msgid "something"
			var msgstrExp = ~/^msgstr "(.*)"/i;//find msgstr "something"
			var contentExp = ~/^"(.*)"/i;//find "something"
			var flagExp = ~/^#, (.*)/i;//find #, something
			
			try{
			line = po.readLine();
			}catch (e:Dynamic) {
				if (Std.string(e) == "Eof")
				{
					trace("end of file");
				}
				break;
			}
			
			
			//check content
			
			if (referenceExp.match(line))//reference
			{
				trace("add reference");
				tb.addReference(referenceExp.matched(1));
				
			}else if ( msgidExp.match(line))//message id
			{
				tb.msgid = msgidExp.matched(1);
				
				if (tb.msgid == "")//start a multiline id
				{
					status = "msgid";
				}
				
			}else if ( msgstrExp.match(line))//message translation
			{
				status = "normal";
				
				tb.msgstr = msgstrExp.matched(1);
				
				if (tb.msgstr == "") //start a multiline str
				{
					status = "msgstr";
					continue;
				}
			}else if (translatorCommentExp.match(line))
			{
				tb.translatorComments.push(translatorCommentExp.matched(1));
				
			}else if (extractedCommentExp.match(line))
			{
				tb.extractedComments.push(extractedCommentExp.matched(1));
				
			}else if (contentExp.match(line)) {//content for id or str
				
				if (status == "msgid")
				{
					tb.msgid += contentExp.matched(1);
					
				}else if (status == "msgstr"){
					tb.msgstr += contentExp.matched(1);
				}
			
			}else {
				//back to normal treat current pending block and start a new one
				
					tb.run(overrideFile);
					cpt++;
					try{
					if (msgstrMap.exists(tb.msgstr))
					{
						//merging
						var etb = msgstrMap.get(tb.msgstr);
						etb.msgid += tb.msgid;
						etb.extractedComments = etb.extractedComments.concat(tb.extractedComments);
						etb.flags = etb.flags.concat(tb.flags);
						etb.translatorComments = etb.translatorComments.concat(tb.translatorComments);
						etb.references = etb.references.concat(tb.references);
						msgstrMap.set(tb.msgstr, etb);
						
						//add fuzzy flag if not exists
						var fuz = etb.flags.filter(function(s) { return s == "fuzzy"; } );
						if (fuz.length == 0)
						{
							etb.flags.push("fuzzy");
						}
						
						duplicated += tb.toReverseString() + "\n";
					}else{
						//res += tb.toReverseString() + "\n";
						msgstrMap.set(tb.msgstr,tb);
					}
					}catch (e:Dynamic) {
							throw "tb.msgstr:" + tb.msgstr + " " + e;
					}
					tb = new TradBlock(basePath);
					status == "normal";
				
				//res += line+"\n";
			}
		}while (line != null);
			
	}
	
	public function generatePoString():String
	{
		for (tb in msgstrMap)
		{
			res += tb.toReverseString() + "\n";
		}
		
		return res;
	}
	
	public function report():String
	{
		var rep = "treated : " + cpt + "\n";
		//rep += "duplicated :\n";
		//for (s in msgstrMap.keys())
		//{
			//var occurence = msgstrMap.get(s);
			//if (occurence > 1)
			//{
				//rep += s +" : " + occurence+"\n";
			//}
		//}
		return rep;
	}
	
	
}
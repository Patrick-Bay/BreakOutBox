/**
 * BreakOutBox JavaScript Host API v1.0
 */
(function() {	
	_box={};
	_box.config={};
	_box.config.version="1.0";
	_box.config.host="%host%"; //Dynamically configured
	_box.config.port=%port%; //Dynamically configured
	/*
	//only if using XMLHttpRequest at some point in the future...
	if (typeof XMLHttpRequest === "undefined") {
		XMLHttpRequest = function () {
			try { 
				return new ActiveXObject("Msxml2.XMLHTTP.6.0"); 
			} catch (e) {}
			try { 
				return new ActiveXObject("Msxml2.XMLHTTP.3.0"); 
			} catch (e) {}
			try { 
				return new ActiveXObject("Microsoft.XMLHTTP"); 
			} catch (e) {}
			throw new Error("This browser does not support XMLHttpRequest.");
		}
	}
	*/
	_box.invoke=function(APICall, settings) {
		try {
			if (($==null) || (typeof ($)=="undefined")) {			
				var err=new Error("BreakOutBox invoke error: jQuery not available through reference \"$\".");
				throw(err);
			}//if
			if ((APICall==null) || (typeof(APICall) == "undefined")) {
				var err=new Error("BreakOutBox invoke error: null or undefined APICall parameter");
				throw(err);
			}//if
			if (APICall.length<1) {
				var err=new Error("BreakOutBox invoke error: APICall parameter is empty");
				throw(err);
			}//if
			if (APICall.indexOf("/")!=0) {
				APICall="/"+APICall; //must always have a preceeding slash
			}//if
			var hostAddress="http://"+this.config.host+":"+this.config.port+APICall;
			if ((settings==null) || (typeof settings=="undefined")) {
				settings=new Object();
			}//if
			settings.type="POST";
			settings.cache=false;
			settings.crossDomain=true;
			settings.dataType="script"; //Works best
			return ($.ajax(hostAddress, settings));		
		} catch (err) {
			var errThrow=new Error("BreakOutBox invoke exception (internal): "+err);
			throw(errThrow);
		}//catch
	}//_box.invoke
})();
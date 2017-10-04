// Browser detection for when you get desparate. A measure of last resort.

// http://rog.ie/post/9089341529/html5boilerplatejs
// sample CSS: html[data-useragent*='Chrome/13.0'] { ... }

// Uncomment the below to use:
// var b = document.documentElement;
// b.setAttribute('data-useragent',  navigator.userAgent);
// b.setAttribute('data-platform', navigator.platform);

	
function initPage(){
	var files;
	//If they use the filepicker, set the file var to the selected value
	$("#fileUploads").on("change", function(event){files = event.target.files[0];});

	//When Submit button is pressed, start loading file into FileReader API
	$("#submitFile").click(function(e){
		e.preventDefault();

		var reader = new FileReader();
		reader.readAsText(files);

		reader.onloadstart = function(evt){
			console.log("File "+files[0]+" is being loaded.");
		}
		reader.onprogress = function(evt){
			console.log("File "+files+" upload in progress.");
		}

		reader.onloadend = function(evt){
			console.log("File "+files+" has been uploaded.");
			processFile(reader.result); //Start Processing the File
		}
	});
	//Process the file in steps
	function processFile(result){
		var _r = result; 	//register incoming FileReader Results
		
		//Ensure that there's actually some text here
		if ( _r != null){
			//Let's convert it to lowercase values first (makes matching easier)
			_r = _r.toLowerCase();	//#workingFine

			//Let's split the string up by using the \n values
			var _sr = new Array();
				_sr = splitString(_r); 	//#workingFine

			//Let's begin the matching process -- The return value is a JS object with "ChatLogItem" array inside of it -- Each array value is an object
			sortArray(_sr);
			//Send the file to the JSON to CSVConverter
			//JSONToCSVConvertor(_sorted_sr.obj)
		}else {
			alert("Something isn't right here...");
		}
	}
	//actually split the File itself.
	function splitString(str){
		var workingText = str;
		var splitEnds = new RegExp('\\n', 'g')
		return workingText.split(splitEnds)			//createArrayForFile();
	}
	//Sort through the lowercase array values to match as necessary
	function sortArray(arr){
		var raw_arr = arr;
		var obj = {	chatLogItem: []	};		//Create the js object to store all of the values

		console.log("Starting Sort");
		
		for ( var i = 0; i < raw_arr.length; i++){
			obj.chatLogItem[i] = { timestamp: "", user: "", type: "", details: "" };
			matchString(raw_arr[i], obj.chatLogItem[i]);  //send in one line of the array at a time to be matched
			console.log(obj.chatLogItem[i]);
		}
		console.log("Finished");

		//Finish the process up by converting it to CSV and downloading it to the computer
		JSONToCSVConvertor(obj.chatLogItem, "Chatlog_Parsed", true);
	}

	//Begin matching the string with values
	function matchString(str, obj){
		var raw_str = str;
		//Let's use the object that we created in the previous sortArray function
		var o = obj;
		//Let's create an object with all of the reg exp values we'll need to test against
		var reObj = createRegExpObj();
		while ((m = reObj.startLineBracketsRE.exec(raw_str)) !== null){
			//Check to see if it contains a time value
			if(reObj.timeRE.test(m[1])) {
				o.timestamp = m[1];
				console.log(o.timestamp);
			}else{
				//Whatever is in the bracket's does not resemble a time stamp
				//Figure out what it is before falling back to the default
				if(m[1].match("authenticator")){
					o.user = "Hidden";
					o.type = "Authentication";
					o.details = "Redacted for Security";
				} else if (m[1].match("server thread/warn")){
					o.user = "Server";
					o.type = "Warning";
					if ((d = reObj.afterColonRE.exec(raw_str)) !== null) {
						o.details = d[1].trim();
					} else {
						o.details = "Parser Error #ms001: Start String ==> "+ raw_str +"<== End String";
					}
				} else if (m[1].match("server thread/info")){
					o.user = "Server";
					o.type = "Info";
				}
			}
			//If there are more bracket values, let's set the index value at the end of the last one and keep going
			if (m.index === reObj.startLineBracketsRE.lastIndex){
				reObj.startLineBrackets.lastIndex++;
			}
		} //End of While loop for bracket testing

		//Once we've finished checking all of the brackets for extra info
		//let's go through go through detail section to see what's happening
		if((o.type == "" && o.user == "") || (o.type == "Info" && o.user == "Server"))  {
			//run the gamut of tests
			matchDetails(raw_str, o, reObj);
		} else {
			//Let's get out of here Jim!
		}
	}

	//Function to create a reg exp js object that stores each of the regexp values
	function createRegExpObj(){
		var obj = {
			startLineBracketsRE: /\[(.*?)\]/g,
			timeRE: new RegExp('((^.*)\\d+\:\\d+\:\\d+)','g'),
			afterColonRE: /]:\s(.+)(?=$)/g,
			speakingRE: new RegExp('[^\:]<(.*?)>', 'g'),
			spokenRE: new RegExp('>(.+)', 'g'),
			connectedCampsSpeakerRE: new RegExp('([\\w]+)(?=\:)', 'g'),
			connectedCampsAfterTimeRE: new RegExp('\]\\s(.*)', 'g'),
			conncetedCampsSpeechRE: new RegExp('[^:\\w](.+)(?=$)', 'g'),
			userAchieveRE: new RegExp('(.*?[^\\w])(?=(?:has just earned the achievement))','g'),
			achieveRE: /(?=(?:has just earned the achievement)).*\[(.*?)\]/g,
			disconRE: /name=(.*?),/g,
			conRE: /(.*?)(?=\[\/\d)/g,
		}
		return obj;
	}
	//Match the content after the colon
	//Should return the object with o = { user: "data", type: "data", details: "data"};
	function matchDetails(str, obj, reObj){
		var s = str;
		var o = obj;
		var re = reObj;
		//First, let's see if there's a ']:' that splits the timestamp and the details
		if ((afterColon = re.afterColonRE.exec(s)) !== null){
			//Is someone talking?
			if ((speaker = re.speakingRE.exec(afterColon[1])) !== null){
				//If so, let's figure out who it is and what they said
				var det = re.spokenRE.exec(afterColon[1]);
				//Then set all the proper values
				o.user = speaker[1].trim();
				o.type = "Talking";
				o.details = det[1].trim();

				if(o.user === "null"){
					nextSpeaker = re.disconRE.exec(afterColon[1]);
					o.user = nextSpeaker[1].trim();
					o.type = "Disconnected";
					o.details = afterColon[1];
				}
			} else if (afterColon[1].match("earned the achievement")) {
				var _u = re.userAchieveRE.exec(afterColon[1]);
				var _ua = re.achieveRE.exec(afterColon[1]);
				
				o.user = _u[1].trim();
				o.type = "Achievement";
				o.details = _ua[1].trim();
			} else if (afterColon[1].match("logged in with entity id")){
				nextLog = re.conRE.exec(afterColon[1]);
				o.user = nextLog[1].trim();
				o.type = "Connected";
				o.details = afterColon[1];
			} else {
				console.log("String is: "+s);
				o.details = afterColon[1].trim();
			}
		} else if ((details = re.connectedCampsAfterTimeRE.exec(s)) !== null) {
			//There's something else that separates the timestamps and the details
			//This was added in for connected camps chat log extras
			if ((speaker = re.connectedCampsSpeakerRE.exec(details[1])) !== null) {
				o.user = speaker[1].trim();
			} else {
				o.user = "Parser Error: #md001";
			}

			if ((spoken = re.conncetedCampsSpeechRE.exec(details[1])) !== null){
				o.details = spoken[1].trim();
				o.type = "Talking";
			} else{
				o.type = "Error";
				o.details = "Parser Error: #md002";
			}

		} else {
			//I have no clue what this is
			o.user = "User Error";
			o.type = "Type Error";
			o.details = "Parser Error: #md003 || Start String ==> "+s+" <== End String";
		}

		return o; //send back the array of text items
	}
	//Function from jsFiddle 
	//Convert JSON to CSV
	function JSONToCSVConvertor(JSONData, ReportTitle, ShowLabel) {
		//If JSONData is not an object then JSON.parse will parse the JSON string in an Object
		var arrData = typeof JSONData != 'object' ? JSON.parse(JSONData) : JSONData;

		var CSV = '';    
		//Set Report title in first row or line

		//CSV += ReportTitle + '\r\n\n';

		//This condition will generate the Label/Header
		if (ShowLabel) {
		    var row = "";
		    
		    //This loop will extract the label from 1st index of on array
		    for (var index in arrData[0]) {
		        
		        //Now convert each value to string and comma-seprated
		        row += index + ',';
		    }

		    row = row.slice(0, -1);
		    
		    //append Label row with line break
		    CSV += row + '\r\n';
		}

		//1st loop is to extract each row
		for (var i = 0; i < arrData.length; i++) {
		    var row = "";
		    
		    //2nd loop will extract each column and convert it in string comma-seprated
		    for (var index in arrData[i]) {
		        row += '"' + arrData[i][index] + '",';
		    }

		    row.slice(0, row.length - 1);
		    
		    //add a line break after each row
		    CSV += row + '\r\n';
		}

		if (CSV == '') {        
		    alert("Invalid data");
		    return;
		}   

		//Generate a file name
		var fileName = "MyReport_";
		//this will remove the blank-spaces from the title and replace it with an underscore
		fileName += ReportTitle.replace(/ /g,"_");   

		//Initialize file format you want csv or xls
		var uri = 'data:text/csv;charset=utf-8,' + escape(CSV);

		// Now the little tricky part.
		// you can use either>> window.open(uri);
		// but this will not work in some browsers
		// or you will not get the correct file extension    

		//this trick will generate a temp <a /> tag
		var link = document.createElement("a");    
		link.href = uri;

		//set the visibility hidden so it will not effect on your web-layout
		link.style = "visibility:hidden";
		link.download = fileName + ".csv";

		//this part will append the anchor tag and remove it after automatic click
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
	}



};

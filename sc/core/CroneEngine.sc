// an audio "engine."
// maintains some DSP processing and provides control over parameters and analysis results
// new engines should inherit from this
CroneEngine {
	// an AudioContext
	var <context;

	// list of registered commands
	var <commands;
	var <commandNames;

	// list of registered parameters
	var <parameters;
	var <parameterNames;
	var <parameterControlBusses;

	// list of registered polls
	var <pollNames;

	*new { arg context, doneCallback;
		^super.new.init(context, doneCallback);
	}

	init { arg argContext, doneCallback;
		commands = List.new;
		commandNames = IdentityDictionary.new;
		parameters = List.new;
		parameterNames = IdentityDictionary.new;
		parameterControlBusses = IdentityDictionary.new;
		pollNames = Set.new;
		context = argContext;
		context.postln;
		fork {
			this.alloc;
			doneCallback.value(this);
		};
	}

	alloc {
		// subclass responsibility to allocate server resources, this method is called in a Routine so it's okay to s.sync
	}

	addPoll { arg name, func;
		name = name.asSymbol;
		CronePollRegistry.register(name, func);
		pollNames.add(name);
	}

	// NB: subclasses should override this if they need to free resources
	// but the superclass method should be called as well
	free {
		postln("CroneEngine.free");
		commands.do({ arg com;
			com.oscdef.free;
		});
		parameterControlBusses.do({ arg cbus;
			cbus.free;
		});
		pollNames.do({ arg name;
			CronePollRegistry.remove(name);
		});
	}

	addCommand { arg name, format, func;
		var idx, cmd;
		name = name.asSymbol;
		this.validateUniqueCommandParameterName(name);
		postln([ "CroneEngine adding command", name, format, func ]);
		if(commandNames[name].isNil, {
			idx = commandNames.size;
			commandNames[name] = idx;
			cmd = Event.new;
			cmd.name = name;
			cmd.format = format;
			cmd.oscdef = OSCdef(name.asSymbol, {
				arg msg, time, addr, rxport;
				// ["CroneEngine rx command", msg, time, addr, rxport].postln;
				func.value(msg);
			}, ("/command/"++name).asSymbol);
			commands.add(cmd);
		}, {
			idx = commandNames[name];
		});
		^idx
	}

	addParameter { arg name, spec;
		var idx;
		name = name.asSymbol;
		this.validateUniqueCommandParameterName(name);
		postln([ "CroneEngine adding parameter", name, spec ]);
		if(parameterNames[name].isNil, {
			var bus;
			idx = parameterNames.size;
			parameterNames[name] = idx;
			bus = Bus.control;
			bus.set(spec.default ?? 0);
			parameterControlBusses[name] = bus;
			parameters.add(
				(
					name: name,
					controlBusIndex: bus.index,
					spec: if (spec.notNil) { spec.asSpec } { nil } // to get around nil.asSpec which is an actual spec in sc
				)
			);
		}, {
			idx = parameterNames[name];
		});
		^idx
	}

	validateUniqueCommandParameterName { |name|
		var errstr = "command and parameter names must be unique.";
		if (commandNames.includes(name)) {
			Error("a command named" + name.quote + "already exists." + errstr).throw
		};
		if (parameterNames.includes(name)) {
			Error("a parameter named" + name.quote + "already exists." + errstr).throw
		};
	}
}


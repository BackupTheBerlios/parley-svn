/*
   Heavily borrowed from the example at:

     http://blog.davclass.com/

   Objectified and extended by:

     Chisel Wright <chisel@herlpacker.co.uk>
*/

/*
    Example usage:

    <script type="text/javascript" src="/path/to/Editable.js"></script>
    <script type="text/javascript">
        // create a new object
        var E  = new YAHOO.widget.EditableElement;
        // override the default callback()
        E.callback = function(){ console.log('my callback called') };
        // initialise the widget
        E.init();
    </script>
*/

(function () {
    YAHOO.widget.EditableElement = function() {
        var Dom             = YAHOO.util.Dom,
            CustomEvent     = YAHOO.util.CustomEvent,
            YU              = YAHOO.util;

        this.config = {
            class_name      : 'editable',
            trigger         : 'click',
            min_input_size  : 0,
            save_on_enter   : true,
            clear_on_escape : true,
            save_button     : true,
            cancel_button   : true
        };
        this.clicked  = false;
        this.contents = false;
        this.input    = false;

        // set up the object to monitor relevant DOM elements
        this.init = function() {
            _items = Dom.getElementsByClassName(this.config.class_name);
            if (_items.length > 0) {
                for (i = 0; i < _items.length; i++) {
                    YU.Event.addListener(
                        _items[i],
                        this.config.trigger,
                        this.triggered,
                        this,
                        true);

                    /* if we need to handle any key events */
                    if (   this.config.save_on_enter
                        || this.config.clear_on_escape
                    ) {
                        YU.Event.addListener(
                            _items[i],
                            'keyup',
                            this.onKeyUp,
                            this,
                            true
                        );
                    }
                }
            }
        };


        // if I new javascript better I probably wouldn't have to
        // write my own max() function
        this._max = function(x,y) {
            if (x>y) { return x; }
            return y;
        };


        this.triggered = function(ev) {
            this.check();
            this.clicked = YU.Event.getTarget(ev, true);
            this.contents = this.clicked.innerHTML;
            this.create_input_field();
        };


        this.onKeyUp = function(p_oEvent) {
            var keyCode = YU.Event.getCharCode(p_oEvent);

            switch (keyCode) {
                case 13: // enter key
                    if (this.config.save_on_enter) {
                        this.check();
                    }
                    break;

                case 27: // enter key
                    if (this.config.save_on_enter) {
                        // ideally we'd reset the box to its original value here
                        this.reset_input_field();
                    }
                    break;

                default:
                    // do nothing
                    break;
            }
        };


        this.create_input_field = function() {
            this.input = YU.Dom.generateId();

            // create a new element for the input
            new_input  = document.createElement('input');
            min_size   = this._max(this.contents.length, this.config.min_size);
            with (new_input) {
                setAttribute('type', 'text');
                setAttribute('id', this.input);
                value = this.contents;
                setAttribute('size', min_size);
                className = 'editable_input';
            }
            this.clicked.innerHTML = '';
            this.clicked.appendChild(new_input);

            // show the save button
            if (this.config.save_button) {
                this.create_save_button();
            }

            // show the cancel button
            if (this.config.cancel_button) {
                this.create_cancel_button();
            }

            // select the newly created input field
            new_input.select();
        };


        this.create_save_button = function() {
            // create the save button
            this.save_input  = YU.Dom.generateId();
            new_save_input   = document.createElement('input');
            with (new_save_input) {
                setAttribute('type', 'button');
                setAttribute('id', this.input);
                value = 'Save';
                className = 'editable_input';
            }
            // add it to the clicked element
            this.clicked.appendChild(new_save_input);
            // add a listener
            YU.Event.addListener(
                new_save_input,
                'click',
                this.check,
                this,
                true
            );
        };


        this.create_cancel_button = function() {
            // create the cancel button
            this.cancel_input  = YU.Dom.generateId();
            new_cancel_input   = document.createElement('input');
            with (new_cancel_input) {
                setAttribute('type', 'button');
                setAttribute('id', this.input);
                value = 'Cancel';
                className = 'editable_input';
            }
            // add it to the clicked element
            this.clicked.appendChild(new_cancel_input);
            // add a listener
            YU.Event.addListener(
                new_cancel_input,
                'click',
                this.reset_input_field,
                this,
                true
            );
        };


        this.reset_input_field = function() {
            this.clicked.innerHTML = this.contents;
            this.clicked  = false;
            this.contents = false;
            this.input    = false;
        };


        this.clear_input = function() {
            if (this.input) {
                var input_value = YU.Dom.get(this.input).value;

                if (input_value.length > 0) {
                    this.clean_input();
                    this.contents_new = input_value;
                }
                else {
                    this.contents_new = '[removed]';
                }
                this.clicked.innerHTML = this.contents_new;

                if (this.contents_new != this.contents) {
                    this.callback();
                }
            }
            this.clicked  = false;
            this.contents = false;
            this.input    = false;
        };


        this.clean_input = function() {
            checkText   = new String(YU.Dom.get(this.input).value);
            regEx1      = /\"/g;
            checkText       = String(checkText.replace(regEx1, ''));
            YU.Dom.get(this.input).value = checkText;
        };


        this.check = function(ev) {
            if (this.clicked) {
                this.clear_input();
            }
        };


        // a default callback() function; you'll want to assign your own in
        // the object you create
        this.callback = function() {
            alert('default callback() called');
        };
    };
})();

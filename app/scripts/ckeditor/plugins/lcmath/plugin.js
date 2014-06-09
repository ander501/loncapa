﻿/**
 * @license Copyright (c) 2014, CKSource - Michigan State University Board of Trustees.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

/**
 * @fileOverview [LON-CAPA Mathematical Formulas](http://ckeditor.com/addon/lcmath) plugin.
 */

'use strict';

( function() {

	var cdn = 'http:\/\/cdn.mathjax.org\/mathjax\/2.2-latest\/MathJax.js?config=MML_HTMLorMML';
    var editor_path = CKEDITOR.basePath + 'plugins/lcmath/math_editor.min.js';
    var parser;
    
    CKEDITOR.scriptLoader.load( editor_path );
    
	CKEDITOR.plugins.add( 'lcmath', {
		lang: 'ar,ca,cs,cy,de,el,en,en-gb,eo,es,fa,fi,fr,gl,he,hr,hu,it,ja,km,nb,nl,no,pl,pt,pt-br,ro,ru,sl,sv,tt,uk,vi,zh,zh-cn', // %REMOVE_LINE_CORE%
		requires: 'widget,dialog',
		icons: 'lcmath',
		hidpi: true, // %REMOVE_LINE_CORE%

		init: function( editor ) {
            LCMATH.ENode.COLORS = ["#000000"];
            parser = new LCMATH.Parser(1, 0); // implicit operators, symbolic mode
			var cls = editor.config.lcMathClass || 'lc-math';

			editor.widgets.add( 'lcmath', {
				inline: true,
				dialog: 'lcmath',
				button: editor.lang.lcmath.button,
				mask: true,
				allowedContent: 'span(!' + cls + ')',
				// Allow style classes only on spans having lcmath class.
				styleToAllowedContentRules: function( style ) {
					var classes = style.getClassesArray();
					if ( !classes )
						return null;
					classes.push( '!' + cls );

					return 'span(' + classes.join( ',' ) + ')';
				},
				pathName: editor.lang.lcmath.pathName,

				template: '<span class="' + cls + '" style="display:inline-block" data-cke-survive=1></span>',

				parts: {
					span: 'span'
				},

				defaults: {
					math: ''
				},

				init: function() {
					var iframe = this.parts.span.getChild( 0 );

					// Check if span contains iframe and create it otherwise.
					if ( !iframe || iframe.type != CKEDITOR.NODE_ELEMENT || !iframe.is( 'iframe' ) ) {
						iframe = new CKEDITOR.dom.element( 'iframe' );
						iframe.setAttributes( {
							style: 'border:0;width:0;height:0',
							scrolling: 'no',
							frameborder: 0,
							allowTransparency: true,
							src: CKEDITOR.plugins.lcmath.fixSrc
						} );
						this.parts.span.append( iframe );
					}

					// Wait for ready because on some browsers iFrame will not
					// have document element until it is put into document.
					// This is a problem when you crate widget using dialog.
					this.once( 'ready', function() {
						// Src attribute must be recreated to fix custom domain error after undo
						// (see iFrame.removeAttribute( 'src' ) in frameWrapper.load).
						if ( CKEDITOR.env.ie )
							iframe.setAttribute( 'src', CKEDITOR.plugins.lcmath.fixSrc );

						this.frameWrapper = new CKEDITOR.plugins.lcmath.frameWrapper( iframe, editor );
						this.frameWrapper.setValue( this.data.math );
					} );
				},

				data: function() {
					if ( this.frameWrapper )
						this.frameWrapper.setValue( this.data.math );
				},

				upcast: function( el, data ) {
					if ( !( el.name == 'span' && el.hasClass( cls ) ) )
						return;

					if ( el.children.length > 1 || el.children[ 0 ].type != CKEDITOR.NODE_TEXT )
						return;

					data.math = CKEDITOR.tools.htmlDecode( el.children[ 0 ].value );

					// Add style display:inline-block to have proper height of widget wrapper and mask.
					var attrs = el.attributes;

					if ( attrs.style )
						attrs.style += ';display:inline-block';
					else
						attrs.style = 'display:inline-block';

					// Add attribute to prevent deleting empty span in data processing.
					attrs[ 'data-cke-survive' ] = 1;

					el.children[ 0 ].remove();

					return el;
				},

				downcast: function( el ) {
					el.children[ 0 ].replaceWith( new CKEDITOR.htmlParser.text( CKEDITOR.tools.htmlEncode( this.data.math ) ) );

					// Remove style display:inline-block.
					var attrs = el.attributes;
					attrs.style = attrs.style.replace( /display:\s?inline-block;?\s?/, '' );
					if ( attrs.style === '' )
						delete attrs.style;

					return el;
				}
			} );

			// Add dialog.
			CKEDITOR.dialog.add( 'lcmath', this.path + 'dialogs/lcmath.js' );

			// Add MathJax script to page preview.
			editor.on( 'contentPreview', function( evt ) {
				evt.data.dataValue = evt.data.dataValue.replace( /<\/head>/,
					'<script src="' + ( editor.config.mathJaxLib ? CKEDITOR.getUrl( editor.config.mathJaxLib ) : cdn ) + '"><\/script><\/head>' );
			} );

			editor.on( 'paste', function( evt ) {
				// Firefox does remove iFrame elements from pasted content so this event do the same on other browsers.
				// Also iFrame in paste content is reason of "Unspecified error" in IE9 (#10857).
				var regex = new RegExp( '<span[^>]*?' + cls + '.*?<\/span>', 'ig' );
				evt.data.dataValue = evt.data.dataValue.replace( regex, function( match ) {
					return  match.replace( /(<iframe.*?\/iframe>)/i, '' );
				} );
			} );
		}
	} );

	/**
	 * @private
	 * @singleton
	 * @class CKEDITOR.plugins.lcmath
	 */
	CKEDITOR.plugins.lcmath = {};

	/**
	 * A variable to fix problems with `iframe`. This variable is global
	 * because it is used in both the widget and the dialog window.
	 *
	 * @private
	 * @property {String} fixSrc
	 */
	CKEDITOR.plugins.lcmath.fixSrc =
		// In Firefox src must exist and be different than about:blank to emit load event.
		CKEDITOR.env.gecko ? 'javascript:true' :
		// Support for custom document.domain in IE.
		CKEDITOR.env.ie ? 'javascript:' +
						'void((function(){' + encodeURIComponent(
							'document.open();' +
							'(' + CKEDITOR.tools.fixDomain + ')();' +
							'document.close();'
						) + '})())' :
		// In Chrome src must be undefined to emit load event.
						'javascript:void(0)';

	/**
	 * Loading indicator image generated by http://preloaders.net.
	 *
	 * @private
	 * @property {String} loadingIcon
	 */
	CKEDITOR.plugins.lcmath.loadingIcon = CKEDITOR.plugins.get( 'lcmath' ).path + 'images/loader.gif';

	/**
	 * Computes predefined styles and copies them to another element.
	 *
	 * @private
	 * @param {CKEDITOR.dom.element} from Copy source.
	 * @param {CKEDITOR.dom.element} to Copy target.
	 */
	CKEDITOR.plugins.lcmath.copyStyles = function( from, to ) {
		var stylesToCopy = [ 'color', 'font-family', 'font-style', 'font-weight', 'font-variant', 'font-size' ];

		for ( var i = 0; i < stylesToCopy.length; i++ ) {
			var key = stylesToCopy[ i ],
				val = from.getComputedStyle( key );
			if ( val )
				to.setStyle( key, val );
		}
	};

	/**
	 * FrameWrapper is responsible for communication between the MathJax library
	 * and the `iframe` element that is used for rendering mathematical formulas
	 * inside the editor.
	 * It lets you create visual mathematics by using the
	 * {@link CKEDITOR.plugins.lcmath.frameWrapper#setValue setValue} method.
	 *
	 * @private
	 * @class CKEDITOR.plugins.lcmath.frameWrapper
	 * @constructor Creates a class instance.
	 * @param {CKEDITOR.dom.element} iFrame The `iframe` element to be wrapped.
	 * @param {CKEDITOR.editor} editor The editor instance.
	 */
	if ( !( CKEDITOR.env.ie && CKEDITOR.env.version == 8 ) ) {
		CKEDITOR.plugins.lcmath.frameWrapper = function( iFrame, editor ) {

			var buffer, preview, value, newValue,
				doc = iFrame.getFrameDocument(),

				// Is lcmath loaded and ready to work.
				isInit = false,

				// Is lcmath parsing.
				isRunning = false,

				// Function called when lcmath is loaded.
				loadedHandler = CKEDITOR.tools.addFunction( function() {
					preview = doc.getById( 'preview' );
					buffer = doc.getById( 'buffer' );
					isInit = true;

					if ( newValue )
						update();

					// Private! For test usage only.
					CKEDITOR.fire( 'lcmathLoaded', iFrame );
				} ),

				// Function called when MathJax finish his job.
				updateDoneHandler = CKEDITOR.tools.addFunction( function() {
					CKEDITOR.plugins.lcmath.copyStyles( iFrame, preview );

					preview.setHtml( buffer.getHtml() );

					editor.fire( 'lockSnapshot' );

					iFrame.setStyles( {
						height: 0,
						width: 0
					} );

					// Set iFrame dimensions.
					var height = Math.max( doc.$.body.offsetHeight, doc.$.documentElement.offsetHeight ),
						width = Math.max( preview.$.offsetWidth, doc.$.body.scrollWidth );

					iFrame.setStyles( {
						height: height + 'px',
						width: width + 'px'
					} );

					editor.fire( 'unlockSnapshot' );

					// Private! For test usage only.
					CKEDITOR.fire( 'lcmathUpdateDone', iFrame );

					// If value changed in the meantime update it again.
					if ( value != newValue )
						update();
					else
						isRunning = false;
				} );

			iFrame.on( 'load', load );

			load();

			function load() {
				doc = iFrame.getFrameDocument();

				if ( doc.getById( 'preview' ) )
					return;

				// Because of IE9 bug in a src attribute can not be javascript
				// when you undo (#10930). If you have iFrame with javascript in src
				// and call insertBefore on such element then IE9 will see crash.
				if ( CKEDITOR.env.ie )
					iFrame.removeAttribute( 'src' );

				doc.write( '<!DOCTYPE html>' +
							'<html>' +
							'<head>' +
								'<meta charset="utf-8">' +
								'<script type="text/x-mathjax-config">' +

									// MathJax configuration, disable messages.
									'MathJax.Hub.Config( {' +
										'showMathMenu: false,' +
										'messageStyle: "none"' +
									'} );' +

									// Get main CKEDITOR form parent.
									'function getCKE() {' +
										'if ( typeof window.parent.CKEDITOR == \'object\' ) {' +
											'return window.parent.CKEDITOR;' +
										'} else {' +
											'return window.parent.parent.CKEDITOR;' +
										'}' +
									'}' +

									// Run MathJax.Hub with its actual parser and call callback function after that.
									// Because MathJax.Hub is asynchronous create MathJax.Hub.Queue to wait with callback.
									'function update() {' +
										'MathJax.Hub.Queue(' +
											'[ \'Typeset\', MathJax.Hub, this.buffer ],' +
											'function() {' +
												'getCKE().tools.callFunction( ' + updateDoneHandler + ' );' +
											'}' +
										');' +
									'}' +

									// Run MathJax for the first time, when the script is loaded.
									// Callback function will be called then it's done.
									'MathJax.Hub.Queue( function() {' +
										'getCKE().tools.callFunction(' + loadedHandler + ');' +
									'} );' +
								'</script>' +

								// Load MathJax lib.
								'<script src="' + ( editor.config.mathJaxLib || cdn ) + '"></script>' +
                                '<style>span.math-error { border: solid 1px red; min-width: 1px; }</style>' +
							'</head>' +
							'<body style="padding:0;margin:0;background:transparent;overflow:hidden">' +
								'<span id="preview"></span>' +

								// Render everything here and after that copy it to the preview.
								'<span id="buffer" style="display:none"></span>' +
							'</body>' +
							'</html>' );
			}

			// Run LC math->MathML
			function update() {
				isRunning = true;

				value = newValue;

				editor.fire( 'lockSnapshot' );

                buffer.setHtml('');
                if (value != '') {
                    try {
                        var root = parser.parse(value);
                        var math = document.createElement("math");
                        math.appendChild(root.toMathML());
                        buffer.append(new CKEDITOR.dom.element(math));
                    } catch (e) {
                        if (e instanceof LCMATH.ParseException) {
                            buffer.append(new CKEDITOR.dom.node(document.createTextNode(value.substring(0, e.from))));
                            var span = document.createElement('span');
                            span.appendChild(document.createTextNode(value.substring(e.from, e.to + 1)));
                            span.className = 'math-error';
                            buffer.append(new CKEDITOR.dom.element(span));
                            if (e.to < value.length - 1) {
                                buffer.append(new CKEDITOR.dom.node(document.createTextNode(value.substring(e.to + 1))));
                            }
                        } else {
                            buffer.appendText(value+': '+e);
                        }
                    }
                }

				// Set loading indicator.
				preview.setHtml( '<img src=' + CKEDITOR.plugins.lcmath.loadingIcon + ' alt=' + editor.lang.lcmath.loading + '>' );

				iFrame.setStyles( {
					height: '16px',
					width: '16px',
					display: 'inline',
					'vertical-align': 'middle'
				} );

				editor.fire( 'unlockSnapshot' );

				// Run MathJax.
				doc.getWindow().$.update( value );
			}

			return {
				/**
				 * Sets the equation text value to be displayed in the `iframe` element inside
				 * the editor. This function will activate the MathJax
				 * library which interprets MathML expressions and converts them into
				 * their representation that is displayed in the editor.
				 *
				 * @param {String} value - equation text with the LON-CAPA math syntax.
				 */
				setValue: function( value ) {
                    newValue = value;
                    
					if ( isInit && !isRunning )
						update();
				}
			};
		};
	} else {
		// In IE8 MathJax does not work stable so instead of using standard
		// frame wrapper it is replaced by placeholder to show pure text in iframe.
		CKEDITOR.plugins.lcmath.frameWrapper = function( iFrame, editor ) {
			iFrame.getFrameDocument().write( '<!DOCTYPE html>' +
				'<html>' +
				'<head>' +
					'<meta charset="utf-8">' +
				'</head>' +
				'<body style="padding:0;margin:0;background:transparent;overflow:hidden">' +
					'<span style="white-space:nowrap;" id="lc"></span>' +
				'</body>' +
				'</html>' );

			return {
				setValue: function( value ) {
					var doc = iFrame.getFrameDocument(),
						lc = doc.getById( 'lc' );

					lc.setHtml( CKEDITOR.tools.htmlEncode( value ) );

					CKEDITOR.plugins.lcmath.copyStyles( iFrame, lc );

					editor.fire( 'lockSnapshot' );

					iFrame.setStyles( {
						width: Math.min( 250, lc.$.offsetWidth ) + 'px',
						height: doc.$.body.offsetHeight + 'px',
						display: 'inline',
						'vertical-align': 'middle'
					} );

					editor.fire( 'unlockSnapshot' );
				}
			};
		};
	}
} )();

/**
 * Sets the path to the MathJax library. It can be both a local
 * resource and a location different than the default CDN.
 *
 * Please note that this must be a full or absolute path.
 *
 *		config.mathJaxLib = 'http:\/\/example.com\/libs\/MathJax.js';
 *
 * @cfg {String} [mathJaxLib='http:\/\/cdn.mathjax.org\/mathjax\/2.2-latest\/MathJax.js?config=MML_HTMLorMML']
 * @member CKEDITOR.config
 */

/**
 * Sets the default class for `span` elements that will be
 * converted into [Mathematical Formulas](http://ckeditor.com/addon/lcmath)
 * widgets.
 *
 * If you set it to the following:
 *
 *		config.lcmathClass = 'my-math';
 *
 * The code below will be recognized as a Mathematical Formulas widget.
 *
 *		<span class="my-math">sqrt(4)=2</span>
 *
 * @cfg {String} [lcmathClass='lc-math']
 * @member CKEDITOR.config
 */

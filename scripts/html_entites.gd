extends Node

const html_entities = {
	"&amp;": "&",
	"&lt;": "<",
	"&gt;": ">",
	"&quot;": "\"",
	"&apos;": "'",
	"&#39;": "'",
	"&nbsp;": " ",

	"&copy;": "©",
	"&reg;": "®",
	"&trade;": "™",

	"&euro;": "€",
	"&pound;": "£",
	"&yen;": "¥",
	"&cent;": "¢",

	"&deg;": "°",
	"&plusmn;": "±",
	"&times;": "×",
	"&divide;": "÷",

	"&hellip;": "…",
	"&ndash;": "–",
	"&mdash;": "—",

	"&lsquo;": "‘",
	"&rsquo;": "’",
	"&ldquo;": "“",
	"&rdquo;": "”",

	"&laquo;": "«",
	"&raquo;": "»",

	"&bull;": "•",
	"&middot;": "·",

	"&larr;": "←",
	"&rarr;": "→",
	"&uarr;": "↑",
	"&darr;": "↓",
	
	# also allow some without semioclon
	"&copy": "©",
	"&reg": "®",
	"&amp": "&",
	"&lt": "<",
	"&gt": ">",
	"&quot": '"',
	"&nbsp": " "
}

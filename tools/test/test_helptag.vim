

function! HelpTags(bid)
	let content = getbufline(a:bid, 1, '$')
	let tags = []
	let lnum = 0
	for text in content
		let lnum += 1
		let p1 = stridx(text, '*')
		if p1 < 0
			continue
		endif
		let p = matchstr(text, '\*\(\S\+\)\*')
		if p == ''
			continue
		endif
		let tag = {}
		let tag.tag = p
		let tag.line = lnum
		let tag.text = text
		let tag.mode = 't'
		call add(tags, tag)
	endfor
	return tags
endfunc


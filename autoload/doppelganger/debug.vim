function! doppelganger#debug#get_virtualtexts() abort
  " Return a Dict in the format, {lnum : virt_text}

  let virt_texts = {}

  const namespace = nvim_get_namespaces().doppelganger
  const marks = nvim_buf_get_extmarks(0, namespace, 0, -1, {'details': 1})
  for m in marks
    let lnum = m[1] + 1
    let info = m[3].virt_text
    call extend(virt_texts, {lnum : map(info, 'v:val[0]')})
  endfor

  return virt_texts
endfunction


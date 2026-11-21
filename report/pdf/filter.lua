-- Pandoc Lua filter for the PDF build of report/report.md (see build.sh).
-- 1. Relative links (../docs/spec.md, references.bib) point to the files on
--    GitHub at the ref in REPO_BLOB, so they work from the PDF.
-- 2. An image alone in a paragraph becomes a figure captioned by its alt
--    text; if an italic "Figure N. ..." paragraph follows (Figure 0), that
--    paragraph becomes the caption instead.
-- 3. A bold "Table N. ..." paragraph just above a table becomes the table's
--    caption, so the two stay on the same page.

local base = os.getenv("REPO_BLOB")

function Link(el)
  local t = el.target
  if t:match("^%a[%w+.-]*:") or t:match("^#") then
    return nil
  end
  if t:match("^%.%./") then
    el.target = base .. t:sub(4)
  else
    el.target = base .. "report/" .. t
  end
  return el
end

local function is_label(inl, el_type, word)
  return #inl == 1 and inl[1].t == el_type
    and pandoc.utils.stringify(inl[1]):match("^" .. word .. " %d") ~= nil
end

function Blocks(blocks)
  local out = pandoc.Blocks({})
  local i = 1
  while i <= #blocks do
    local b, nxt = blocks[i], blocks[i + 1]
    if b.t == "Para" and #b.content == 1 and b.content[1].t == "Image" then
      local img = b.content[1]
      local cap = img.caption
      if nxt and nxt.t == "Para" and is_label(nxt.content, "Emph", "Figure") then
        cap = nxt.content[1].content
        i = i + 1
      end
      out:insert(pandoc.Figure(pandoc.Plain({ img }), { long = { pandoc.Plain(cap) } }))
    elseif b.t == "Para" and is_label(b.content, "Strong", "Table")
        and nxt and nxt.t == "Table" then
      nxt.caption = { long = { pandoc.Plain(b.content[1].content) } }
      out:insert(nxt)
      i = i + 1
    else
      out:insert(b)
    end
    i = i + 1
  end
  return out
end

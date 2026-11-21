-- Pandoc Lua filter for the PDF build of report/report.md (see build.sh).
-- 1. Relative links (../docs/spec.md, references.bib) point to the files on
--    GitHub at the ref in REPO_BLOB, so they work from the PDF.
-- 2. APA 7 tables and figures: a bold "Table N" or "Figure N" paragraph, an
--    italic title paragraph, then the table or the image, become one table or
--    figure whose caption is the number and the title on two lines. An italic
--    "Note." paragraph that follows is kept with it on the same page.
-- 3. Otherwise, an image alone in a paragraph becomes a figure captioned by its
--    alt text, and a bold "Table N. ..." paragraph just above a table becomes
--    the table's caption.

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

local function is_number(b, word)
  return b and b.t == "Para" and #b.content == 1 and b.content[1].t == "Strong"
    and pandoc.utils.stringify(b.content[1]):match("^" .. word .. " %d+$") ~= nil
end

local function is_title(b)
  return b and b.t == "Para" and #b.content == 1 and b.content[1].t == "Emph"
end

local function is_image(b)
  return b and b.t == "Para" and #b.content == 1 and b.content[1].t == "Image"
end

local function is_note(b)
  return b and b.t == "Para" and #b.content >= 1 and b.content[1].t == "Emph"
    and pandoc.utils.stringify(b.content[1]) == "Note."
end

local function apa_caption(num, title)
  return { long = { pandoc.Plain({ num.content[1], pandoc.LineBreak(), title.content[1] }) } }
end

function Blocks(blocks)
  local out = pandoc.Blocks({})
  local i = 1
  while i <= #blocks do
    local b, b2, b3 = blocks[i], blocks[i + 1], blocks[i + 2]
    local float = nil
    if is_number(b, "Table") and is_title(b2) and b3 and b3.t == "Table" then
      b3.caption = apa_caption(b, b2)
      float = b3
      i = i + 3
    elseif is_number(b, "Figure") and is_title(b2) and is_image(b3) then
      float = pandoc.Figure(pandoc.Plain({ b3.content[1] }), apa_caption(b, b2))
      i = i + 3
    elseif is_number(b, "Figure") and is_title(b2) and b3 and b3.t == "Figure" then
      -- pandoc 3 turns an image alone in a paragraph into a Figure already
      b3.caption = apa_caption(b, b2)
      float = b3
      i = i + 3
    end
    if float then
      local inner = { float }
      if is_note(blocks[i]) then
        table.insert(inner, blocks[i])
        i = i + 1
      end
      out:insert(pandoc.Div(inner, pandoc.Attr("", { "float" })))
    elseif is_image(b) then
      local img = b.content[1]
      local cap = img.caption
      if b2 and b2.t == "Para" and is_label(b2.content, "Emph", "Figure") then
        cap = b2.content[1].content
        i = i + 1
      end
      out:insert(pandoc.Figure(pandoc.Plain({ img }), { long = { pandoc.Plain(cap) } }))
      i = i + 1
    elseif b.t == "Para" and is_label(b.content, "Strong", "Table")
        and b2 and b2.t == "Table" then
      b2.caption = { long = { pandoc.Plain(b.content[1].content) } }
      out:insert(b2)
      i = i + 2
    else
      out:insert(b)
      i = i + 1
    end
  end
  return out
end

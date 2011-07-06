function parseargs(s)
  local arg = {}
  string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end
    
function collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

function collectFromFile(xmlFileName)
	if (not err) then
		local xmlText=love.filesystem.read( xmlFileName );
        return collect(xmlText);
	else
		return nil,err;
	end
end

function printTable(data)
    return to_string(data,0)
end

function to_string(data, indent) 
    local str = "" 

    if(indent == nil) then 
        indent = 0 
    end 

    -- Check the type 
    if(type(data) == "string") then 
        str = str .. (" "):rep(indent) .. data .. "\n" 
    elseif(type(data) == "number") then 
        str = str .. (" "):rep(indent) .. data .. "\n" 
    elseif(type(data) == "boolean") then 
        if(data == true) then 
            str = str .. "true" 
        else 
            str = str .. "false" 
        end 
    elseif(type(data) == "table") then 
        local i, v 
        for i, v in pairs(data) do 
            -- Check for a table in a table 
            if(type(v) == "table") then 
                str = str .. (" "):rep(indent) .. i .. ":\n" 
                str = str .. to_string(v, indent + 2) 
            else 
                str = str .. (" "):rep(indent) .. i .. ": " .. to_string(v, 0) 
            end 
        end 
    else 
        print_debug(1, "Error: unknown data type: %s", type(data)) 
    end 
    return str 
end
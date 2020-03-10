function version()
	return "1.1.0"
end

function exec(sql, ...)
	local stmt = db.prepare(sql)
	count = stmt:exec(...)
	return count
end

function batch_exec(sql, n, ...)
    local stmt = db.prepare(sql)
    local bindcnt = stmt:bind_param_cnt()
    local counts = {}

    local start
    local last = 0
    local param ={...}
    for i = 1, n do
        start = last + 1
        last = last + bindcnt
        status, res = pcall(function () return stmt:exec(unpack(param, start, last)) end)
        if status == false then
            return {cnts=counts, err=res}
        end
        counts[i] = res
    end
    return {cnts=counts, err=nil}
end

function batchsql_exec(...)
    local counts = {}
    local sql = {...}

    for i = 1, #sql do
        status, res = pcall(db.exec, sql[i])
        if status == false then
            return {cnts=counts, err=res}
        end
        counts[i] = res
    end
    return {cnts=counts, err=nil}
end

function query_begin(sql, ...)
    local stmt = db.prepare(sql)
    local rs = stmt:query(...)
    local r = {}
    local colcnt = rs:colcnt()
    local colmetas = stmt:column_info()
    while rs:next() do
        local k = {rs:get()}
        for i = 1, colcnt do
            if k[i] == nil then
                k[i] = {}
            end
        end
        table.insert(r, k)
    end
    if (#r == 0) then
        return {colcnt=colcnt, rowcnt=0 , rows=nil, colmetas=colmetas}
    end

    return {colcnt=colcnt, rowcnt=#r, rows=r, colmetas=colmetas, snapshot=db.getsnap()}
end
	
function query_next(snap, sql, ...)
	db.open_with_snapshot(snap)
	local rs = db.query(sql, ...)
	local r = {}
	local colcnt = rs:colcnt()
	while rs:next() do 
		local k = {rs:get()}
		for i = 1, colcnt do 
			if k[i] == nil then
				k[i] = {}
			end
		end
		table.insert(r, k)
	end
	if (#r == 0) then
		return {colcnt=colcnt, rowcnt=0 , rows=nil}
	end

	return {colcnt=colcnt, rowcnt=#r, rows=r}
end

function getmeta(sql)
	local stmt = db.prepare(sql)
	return {colmetas=stmt:column_info(), bindcnt=stmt:bind_param_cnt()}
end

function constructor()
	db.exec("create table sample(num int, data text)")
end

abi.register(exec, batch_exec, batchsql_exec)
abi.register_view(version, query_begin, query_next, getmeta)

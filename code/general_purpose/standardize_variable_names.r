standardize_variable_names = function(obj){
  oldnames = names(obj)
  newnames = tolower(oldnames)
  newnames = gsub("[.]+","_",newnames)
  if("data.table" %in% class(obj)){
    require(data.table)
    setnames(obj, oldnames, newnames)
  } else {
    names(obj) = newnames
  }
  obj
}

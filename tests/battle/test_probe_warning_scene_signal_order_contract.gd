extends RefCounted

const AggregationContract = preload("res://tests/battle/test_warning_aggregation_contract.gd")

func run() -> Array[String]:
	return AggregationContract.new().run()

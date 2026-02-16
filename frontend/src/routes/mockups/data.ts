// Static data for mockups based on real production recipes

export const recipes = [
	{
		id: '1',
		title: 'Simple Spaghetti Carbonara, Step-by-Step',
		description:
			'Transform a few pantry staples, plus guanciale, pancetta, or bacon, into silky, rich spaghetti carbonara. Our easy recipe comes together in just 22 minutes.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/6917aa378ac0eb7fbdadae2a/16:9/w_4351,h_2447,c_limit/simple-carbonara_RECIPE_V1_111125_13849_VOG_final.jpg',
		total_time_minutes: 22,
		servings: '4 servings',
		tags: [{ id: '1', name: 'dinner' }, { id: '2', name: 'pasta' }],
		ingredients: [
			{ text: '6 oz. guanciale, pancetta, or bacon, cut into about ½" pieces' },
			{ text: '3 large egg yolks' },
			{ text: '1 large egg' },
			{ text: '1½ oz. finely grated Pecorino Romano, plus more for serving' },
			{ text: 'Freshly ground black pepper' },
			{ text: '12 oz. spaghetti' },
			{ text: 'Kosher salt' }
		],
		instructions: [
			{ text: 'Cook guanciale in a large skillet over medium heat, stirring occasionally, until fat has rendered and guanciale is golden and crisp, 8-10 minutes.' },
			{ text: 'Meanwhile, whisk egg yolks, whole egg, and Pecorino in a medium bowl until smooth. Season with lots of pepper.' },
			{ text: 'Cook pasta in a large pot of boiling salted water, stirring occasionally, until very al dente, about 2 minutes less than package directions.' },
			{ text: 'Using tongs, transfer pasta to skillet with guanciale. Add ½ cup pasta cooking liquid.' },
			{ text: 'Remove skillet from heat. Pour egg mixture over pasta and toss vigorously, adding more pasta cooking liquid as needed, until sauce is thickened and creamy.' },
			{ text: 'Divide pasta among bowls. Top with more Pecorino and pepper.' }
		],
		prep_time_minutes: 10,
		cook_time_minutes: 12,
		notes: null
	},
	{
		id: '2',
		title: 'Ruffled Mushroom Pot Pie',
		description:
			'Topping a classic mushroom pot pie with crunchy, scrunched-up phyllo takes the comfort food classic from good to great.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/6765f1bd9ae953633b06a3d0/16:9/w_4845,h_2726,c_limit/ruffled-mushroom-pot-pie_LEDE_V2_110624_7344_VOG_final.jpg',
		total_time_minutes: 75,
		servings: '4-6 servings',
		tags: [{ id: '1', name: 'dinner' }, { id: '3', name: 'vegetarian' }],
		ingredients: [],
		instructions: [],
		prep_time_minutes: 20,
		cook_time_minutes: 55,
		notes: null
	},
	{
		id: '3',
		title: 'Herby Cauliflower Fritters',
		description:
			'Frozen cauliflower deserves to be more than a side. Here, a quick zap in the microwave primes the veggie crumbles to become a hearty vegetarian main.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/65bbdfe22c3c1e1bdd2c7f07/16:9/w_6176,h_3474,c_limit/20231207-0324-DIS-7172.jpg',
		total_time_minutes: 30,
		servings: '4 servings',
		tags: [{ id: '1', name: 'dinner' }, { id: '3', name: 'vegetarian' }],
		ingredients: [],
		instructions: [],
		prep_time_minutes: 10,
		cook_time_minutes: 20,
		notes: null
	},
	{
		id: '4',
		title: 'Ditalini and Peas in Parmesan Broth',
		description:
			'This pasta and peas recipe is all about the broth: A creamy, rich, Parmesan-fortified chicken broth brings together all of the flavors.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/6969889e09bb7d32880e3e888/16:9/w_5456,h_3069,c_limit/Ditalini_and_Peas_In_Parm_Broth_2798.jpeg',
		total_time_minutes: 45,
		servings: '4-6 servings',
		tags: [{ id: '1', name: 'dinner' }, { id: '2', name: 'pasta' }],
		ingredients: [],
		instructions: [],
		prep_time_minutes: 15,
		cook_time_minutes: 30,
		notes: null
	},
	{
		id: '5',
		title: 'Brown Butter Berbere Kabocha Squash',
		description:
			'Sweet kabocha gets tossed in warm berbere spice and roasted, topped with a lime-brown-butter sauce and peanuts for a flavorful veg main or side.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/65c53e42bc3197825ca9b16f/16:9/w_7664,h_4311,c_limit/20240207-WEB-0366.jpg',
		total_time_minutes: 50,
		servings: '4-6 servings',
		tags: [{ id: '3', name: 'vegetarian' }, { id: '4', name: 'side' }],
		ingredients: [],
		instructions: [],
		prep_time_minutes: 15,
		cook_time_minutes: 35,
		notes: null
	},
	{
		id: '6',
		title: 'Boozy Cherry and Chocolate Pavlova',
		description:
			'Pavlova meets Black Forest cake in a holiday dessert designed to wow: a meringue shell, a pillowy middle, sweet-tart cherries, and dark chocolate ganache.',
		source_domain: 'bonappetit.com',
		image_url:
			'https://assets.bonappetit.com/photos/68dbf7bcb517a261c588c282/16:9/w_4992,h_2808,c_limit/black-forest-pavlova_RECIPE_V1_092525_2165_VOG_Badge_final.jpg',
		total_time_minutes: 120,
		servings: '8 servings',
		tags: [{ id: '5', name: 'dessert' }],
		ingredients: [],
		instructions: [],
		prep_time_minutes: 30,
		cook_time_minutes: 90,
		notes: null
	}
];

export const featuredRecipe = recipes[0];
export const dinnerIdeas = recipes.slice(0, 4);
export const recentlyAdded = recipes.slice(2, 6);
